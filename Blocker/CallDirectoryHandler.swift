import CallKit
import Foundation
import SilenciaKit

/// The Call Directory extension entry point. iOS invokes `beginRequest` when the
/// user enables the extension or when the app calls `reloadExtension`.
///
/// All the hard logic (which numbers, in what order) lives in `SilenciaKit` and is
/// unit-tested headless. This class only bridges that ascending stream to CallKit,
/// applying the memory discipline from implementation-plan.md §2.3.
final class CallDirectoryHandler: CXCallDirectoryProvider {
    /// Autorelease boundary size — CallKit bridging accumulates transient objects,
    /// so we drain the pool every N entries to hold memory flat under the ~6 MB budget.
    private let chunkSize = 100_000

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // The extension must never materialize the 12M-number list. It reads the
        // small, validated plan and streams it. `bundledDefault` is the ship-safe
        // source; the App Group config (active tier + user entries) is layered in
        // by the main app before it triggers a reload.
        let plan = activePlan()

        if context.isIncremental {
            // Incremental reloads (user added/removed an entry) recompute deltas in
            // the app; a full deterministic rewrite is always a valid fallback.
            context.removeAllBlockingEntries()
        }

        var iterator = plan.numbers.makeIterator()
        var emitted = 0
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

        NSLog("[SilenciaBlocker] emitted \(emitted) blocking entries")
        context.completeRequest()
    }

    /// Builds the plan the extension should apply. Reads active ranges + user runs
    /// from the App Group when available (see `SharedConfig`), else falls back to
    /// the full bundled Arcep set.
    private func activePlan() -> BlockingPlan {
        if let config = SharedConfig.load() {
            return config.plan()
        }
        return BlockingPlan(arcepRanges: RangeData.bundledDefault.ranges)
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // iOS may kill a long request (isInterrupted); it re-invokes us and the full
        // reload path recomputes everything deterministically, so this is recoverable.
        NSLog("[SilenciaBlocker] request failed: \(error.localizedDescription)")
    }
}
