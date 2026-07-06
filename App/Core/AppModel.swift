import Foundation
import SilenciaKit
import SwiftUI

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
    @Published private(set) var isReloading = false
    @Published var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: Self.onboardingKey) }
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

    /// Startup: check the extension status. Called from the root view's `.task`.
    func start() async {
        await refreshExtensionStatus()
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

    /// Writes the config the extension reads, then asks iOS to re-run it.
    private func persistAndReload() {
        do {
            try config.save()
        } catch {
            // Non-fatal (e.g. App Group container unavailable in some dev setups):
            // the extension falls back to the bundled full range set.
            NSLog("[Silencia] config save failed: \(error.localizedDescription)")
        }
        Task { await reloadExtension() }
    }

    /// Triggers an extension reload with the staged progress UI (§3.2: the
    /// extension can't report progress; the app shows an indeterminate state).
    func reloadExtension() async {
        guard !isReloading else { return }
        isReloading = true
        defer { isReloading = false }
        if let errorMessage = await bridge.reload() {
            NSLog("[Silencia] extension reload failed: \(errorMessage)")
        }
        await refreshExtensionStatus()
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
