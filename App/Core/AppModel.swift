import Foundation
import SilenciaKit
import SwiftUI
import UIKit

/// Where the paged Call Directory load stands, as the UI sees it.
enum LoadProgress: Equatable {
    case idle
    /// A sync loop is driving reload rounds; `loaded`/`total` come from the
    /// extension's persisted cursor — real, determinate progress.
    case loading(loaded: Int64, total: Int64)
    case complete
    case failed(String)
}

/// The app's single source of truth. Owns the shared config (ranges, user
/// entries), persists it to the App Group, and orchestrates extension reloads.
/// All *decisions* (validation, plan math) live in SilenciaKit and are
/// unit-tested headless; this class is the thin stateful shell around them.
///
/// Silencia is paid upfront (business-plan.md §1): buying the app on the App
/// Store *is* the lifetime deal, so there is no tier, entitlement, or StoreKit
/// code anywhere — every install blocks every range.
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var userEntries: [BlockEntry]
    @Published private(set) var extensionStatus: ExtensionStatus = .unknown
    @Published private(set) var loadProgress: LoadProgress = .idle
    @Published var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: Self.onboardingKey) }
    }

    /// Kept for the views that only need "is a load in flight".
    var isReloading: Bool {
        if case .loading = loadProgress { return true }
        return false
    }

    let rangeData: RangeData

    private let bridge = ExtensionBridge()
    private static let onboardingKey = "onboardingComplete"

    init() {
        let saved = SharedConfig.load()
        // Bundled ranges are the floor; a persisted *newer* dataset (future remote
        // refresh, §3.4) wins.
        let bundled = RangeData.loadBundled()
        if let savedData = saved?.rangeData, savedData.version > bundled.version {
            rangeData = savedData
        } else {
            rangeData = bundled
        }
        userEntries = saved?.userEntries ?? []
        onboardingComplete = UserDefaults.standard.bool(forKey: Self.onboardingKey)

        #if DEBUG
            if let screen = DebugScreen.fromLaunchArguments() {
                configure(for: screen)
            }
        #endif
    }

    #if DEBUG
        /// When set, `refreshExtensionStatus()` reports this instead of asking iOS —
        /// lets the screen harness render states the simulator can't produce.
        var debugStatusOverride: ExtensionStatus?

        private func configure(for screen: DebugScreen) {
            switch screen {
            case .dashboard:
                debugStatusOverride = .enabled
            case .paused:
                debugStatusOverride = .disabled
            case .loading:
                // Mid-load snapshot: 7.58M / 12M → 7 full bricks + a partial 8th.
                debugStatusOverride = .enabled
                loadProgress = .loading(loaded: 7_580_000, total: 12_000_000)
            case .blocklist:
                debugStatusOverride = .enabled
                // Transient demo entries (design screen 07) — not persisted.
                userEntries = ["06 12 34 56 78", "08 99 70", "07 56 12 34 99"]
                    .compactMap { BlockEntry(raw: $0) }
            default:
                break
            }
        }
    #endif

    // MARK: Derived state

    var config: SharedConfig {
        SharedConfig(rangeData: rangeData, userEntries: userEntries)
    }

    /// The plan the extension will stream — drives every count shown in the UI.
    var activePlan: BlockingPlan {
        config.plan()
    }

    // MARK: Lifecycle

    /// Startup: check the extension status and resume any unfinished paged load.
    /// Called from the root view's `.task`.
    func start() async {
        // Persist the config *before* the extension can run so it streams exactly
        // the app's plan. Without this the extension falls back to its own bundled
        // source, and if that ever diverges from the app's the fingerprints won't
        // match — the completion check never passes and the load re-drives forever
        // (reload loop after full load). See `persistConfig`.
        persistConfig()
        await refreshExtensionStatus()
        if extensionStatus.isEnabled {
            await syncExtension()
        }
    }

    /// Foreground hook (`scenePhase == .active`): re-check status and resume an
    /// unfinished load — this is what makes an interrupted first load self-healing.
    func onForeground() async {
        await refreshExtensionStatus()
        if extensionStatus.isEnabled {
            await syncExtension()
        }
    }

    func refreshExtensionStatus() async {
        #if DEBUG
            if let debugStatusOverride {
                extensionStatus = debugStatusOverride
                return
            }
        #endif
        extensionStatus = await bridge.status()
    }

    // MARK: Mutations (every one persists to the App Group, then reloads)

    /// Validates and, if valid, adds a custom entry. The caller renders the outcome
    /// (feedback banner, …).
    func addEntry(raw: String) -> BlockListLogic.AddOutcome {
        let outcome = BlockListLogic.evaluateAdd(
            raw: raw,
            existing: userEntries,
            arcepRanges: rangeData.ranges
        )
        if case let .added(entry) = outcome {
            userEntries.append(entry)
            persistAndReload()
        }
        return outcome
    }

    func removeEntry(_ entry: BlockEntry) {
        userEntries.removeAll { $0.id == entry.id }
        persistAndReload()
    }

    /// Writes the config the extension reads. Called eagerly at startup and after
    /// every mutation so the app and the extension always agree on *which* plan the
    /// paged-load cursor refers to: the extension streams `SharedConfig.load()`,
    /// and the app's completion check compares fingerprints against `activePlan`.
    /// If the two ever built different plans the check would never pass and the
    /// load would re-drive forever — the "reload loop after full load" this guards.
    private func persistConfig() {
        do {
            try config.save()
        } catch {
            // Non-fatal (e.g. App Group container unavailable in some dev setups):
            // the extension falls back to the bundled full range set.
            NSLog("[Silencia] config save failed: \(error.localizedDescription)")
        }
    }

    /// Writes the config the extension reads, then drives the paged reload.
    private func persistAndReload() {
        persistConfig()
        Task { await syncExtension() }
    }

    /// True when the enabled extension hasn't fully loaded the current plan —
    /// drives background-task scheduling and foreground resume.
    var needsSync: Bool {
        guard let state = LoaderState.load() else { return true }
        return state.planFingerprint != activePlan.fingerprint || !state.isComplete
    }

    /// Drives reload rounds until the extension's persisted cursor says the current
    /// plan is fully loaded (paged-loading-plan.md §2.7). Each round the extension
    /// emits one ≤1.8M page; CallKit caps requests at 2M entries, so this loop *is*
    /// how the 12M set gets in. Holds a background-task assertion so leaving the
    /// app doesn't stall the load; if iOS still suspends us, the persisted cursor
    /// lets any later trigger (foreground, BGProcessingTask) resume seamlessly.
    func syncExtension() async {
        #if DEBUG
            // Screen-harness runs stage loadProgress themselves; a real sync loop
            // would overwrite the staged state (and fail on the simulator anyway).
            if debugStatusOverride != nil { return }
        #endif
        guard extensionStatus.isEnabled, !isSyncing else { return }
        isSyncing = true
        beginBackgroundAssertion()
        defer {
            endBackgroundAssertion()
            isSyncing = false
        }

        var invalidatedOnce = false
        var rounds = 0
        while !Task.isCancelled {
            // Recomputed every round: a mutation mid-loop simply retargets the loop
            // (the extension restarts via the fingerprint mismatch, decision row 3).
            let plan = activePlan
            if let state = LoaderState.load(),
               state.planFingerprint == plan.fingerprint,
               state.isComplete
            {
                loadProgress = .complete
                return
            }

            // +3: one spare for an invalidation retry, two for a mid-loop restart.
            let bound = PagedLoader.pageCount(totalEntries: plan.totalEntries) + 3
            guard rounds < bound else {
                loadProgress = .failed("Le chargement n'a pas abouti.")
                return
            }

            loadProgress = .loading(
                loaded: LoaderState.load()?.entriesLoaded ?? 0,
                total: plan.totalEntries
            )

            if let errorMessage = await bridge.reload() {
                NSLog("[Silencia] reload round failed: \(errorMessage)")
                guard !invalidatedOnce else {
                    loadProgress = .failed(errorMessage)
                    return
                }
                // One recovery attempt: drop the cursor, rebuild from scratch.
                invalidatedOnce = true
                LoaderState.invalidate()
            }
            rounds += 1
        }
        // Cancelled (background time expired): the cursor is persisted; the next
        // trigger resumes exactly where this loop stopped.
    }

    /// Recovery hatch (dashboard « Réessayer », Settings maintenance): drop the
    /// cursor and rebuild the whole store deterministically.
    func retrySync() async {
        LoaderState.invalidate()
        loadProgress = .idle
        await syncExtension()
    }

    private var isSyncing = false

    // MARK: Background-task assertion (keeps a load alive when the app is left)

    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private func beginBackgroundAssertion() {
        endBackgroundAssertion()
        backgroundTaskID = UIApplication.shared
            .beginBackgroundTask(withName: "silencia.sync") { [weak self] in
                // Expiration is delivered on the main thread.
                MainActor.assumeIsolated {
                    self?.endBackgroundAssertion()
                }
            }
    }

    private func endBackgroundAssertion() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }

    #if targetEnvironment(simulator)
        /// Simulator-only: real activation requires the iOS Settings toggle, which
        /// the simulator can't exercise end-to-end. Lets the dev flow proceed.
        func simulateActivation() {
            extensionStatus = .enabled
        }

        /// The simulator's status query often errors; treat that as "unknown" so
        /// UI states keyed on `.unavailable` don't flicker while polling.
        func clearUnavailableStatus() {
            if case .unavailable = extensionStatus {
                extensionStatus = .unknown
            }
        }
    #endif
}
