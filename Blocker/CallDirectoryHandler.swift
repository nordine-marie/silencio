import CallKit
import Foundation
import SilenciaKit

/// The Call Directory extension entry point. iOS invokes `beginRequest` when the
/// user enables the extension or when the app calls `reloadExtension`.
///
/// All the hard logic (which numbers, in what order, **which page comes next**)
/// lives in `SilenciaKit` and is unit-tested headless. This class only bridges one
/// page of that ascending stream to CallKit, applying the memory discipline from
/// implementation-plan.md §2.3.
///
/// Paging (paged-loading-plan.md): CallKit rejects any request adding more than
/// 2,000,000 entries — a per-request cap, not a store cap. So each invocation
/// emits at most `PagedLoader.pageSize` entries, advancing a cursor persisted in
/// the App Group; the app drives reload rounds until the plan is fully loaded.
final class CallDirectoryHandler: CXCallDirectoryProvider {
    /// Autorelease boundary size — CallKit bridging accumulates transient objects,
    /// so we drain the pool every N entries to hold memory flat under the ~6 MB budget.
    private let chunkSize = 100_000

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // The extension must never materialize the number list. It reads the
        // small, validated plan and streams one page of it. `bundledDefault` is
        // the ship-safe source; the App Group config (range data + user entries)
        // is layered in by the main app before it triggers a reload.
        let plan = activePlan()
        let action = PagedLoader.nextAction(
            isIncremental: context.isIncremental,
            state: LoaderState.load(),
            planFingerprint: plan.fingerprint,
            totalEntries: plan.totalEntries
        )

        // Diagnostic: a load that never "sticks" (reload loop after full load) shows
        // up here as either repeated `emitFirstPage` (iOS keeps handing us
        // non-incremental contexts, so the cursor never advances past page 1) or a
        // `fingerprint` that disagrees with the app's. Cheap to log, decisive to read.
        NSLog(
            "[SilenciaBlocker] beginRequest isIncremental=\(context.isIncremental) "
                + "action=\(action) fingerprint=\(plan.fingerprint) total=\(plan.totalEntries)"
        )

        let start: Int64
        switch action {
        case .emitFirstPage:
            // Non-incremental context: the system store is already empty.
            start = 0
        case .restartAndEmitFirstPage:
            // Cursor missing or for a different plan: deterministic rebuild.
            context.removeAllBlockingEntries()
            start = 0
        case let .emitPage(startIndex):
            start = startIndex
        case .alreadyComplete:
            NSLog("[SilenciaBlocker] plan already fully loaded (\(plan.totalEntries) entries)")
            context.completeRequest()
            return
        }

        var iterator = plan
            .pageNumbers(startIndex: start, maxCount: PagedLoader.pageSize)
            .makeIterator()
        var emitted: Int64 = 0
        var done = false
        while !done {
            autoreleasepool {
                var inChunk = 0
                while inChunk < chunkSize {
                    guard let number = iterator.next() else { done = true; break }
                    context.addBlockingEntry(withNextSequentialPhoneNumber: number)
                    inChunk += 1
                    emitted += 1
                }
            }
        }

        // Optimistic save before completeRequest — the deliberate trade analysed in
        // paged-loading-plan.md §2.8. `requestFailed` rolls it back; the app's
        // recovery paths cover the residual hard-kill window.
        let newState = LoaderState(
            planFingerprint: plan.fingerprint,
            entriesLoaded: start + emitted,
            totalEntries: plan.totalEntries
        )
        do {
            try newState.save()
        } catch {
            // Without a cursor the next round rebuilds from scratch — safe, just slower.
            NSLog("[SilenciaBlocker] cursor save failed: \(error.localizedDescription)")
        }

        NSLog(
            "[SilenciaBlocker] page emitted: \(emitted) entries "
                + "(\(newState.entriesLoaded)/\(plan.totalEntries))"
        )
        context.completeRequest()
    }

    /// Builds the plan the extension should apply. Reads active ranges + user runs
    /// from the App Group when available (see `SharedConfig`) — the app persists it
    /// before any reload, so this is the normal path and it matches the app's plan
    /// exactly. The fallback uses `RangeData.loadBundled()` (the *same* source the
    /// app builds its plan from), not the hardcoded `bundledDefault`, so even if the
    /// config is momentarily absent the two never disagree on the plan fingerprint.
    private func activePlan() -> BlockingPlan {
        if let config = SharedConfig.load() {
            return config.plan()
        }
        return BlockingPlan(arcepRanges: RangeData.loadBundled().ranges)
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for _: CXCallDirectoryExtensionContext, withError error: Error) {
        // iOS rolled back everything this request added, so the optimistically
        // saved cursor is now wrong: drop it. The next round rebuilds
        // deterministically from zero (decision row 2).
        LoaderState.invalidate()
        NSLog("[SilenciaBlocker] request failed: \(error.localizedDescription)")
    }
}
