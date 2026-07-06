import Foundation

/// The paged-loading decision logic shared by the app (driver) and the extension
/// (streamer) — paged-loading-plan.md §2.4. Pure and exhaustively unit-tested:
/// *which entries the extension emits next* is decided here, never ad hoc inside
/// the memory-constrained extension.
public enum PagedLoader {
    /// CallKit rejects any single `beginRequest` that adds more than this many
    /// entries — observed on device: « Cannot add entries since it would exceed
    /// maximum allowed entries (2000000) », CXCallDirectoryManager error Code=5.
    /// It is a per-request cap, not a store cap: pages accumulate across rounds.
    public static let systemMaxEntriesPerRequest: Int64 = 2_000_000

    /// Entries emitted per request: 10% headroom under the system cap. Worst case
    /// (12M Arcep + the 500k custom-entry budget from implementation-plan.md §3.3)
    /// is 7 pages.
    public static let pageSize: Int64 = 1_800_000

    /// What one `beginRequest` invocation should do.
    public enum Action: Equatable, Sendable {
        /// Non-incremental context: the system store is empty. Any persisted cursor
        /// is meaningless — start the stream from 0 (no `removeAll` needed or allowed).
        case emitFirstPage
        /// Incremental context but no trustworthy cursor (missing, stale schema, or
        /// a different plan): wipe the store and start from 0.
        case restartAndEmitFirstPage
        /// Continue the canonical ascending stream from the persisted cursor.
        case emitPage(startIndex: Int64)
        /// The current plan is fully loaded; add nothing.
        case alreadyComplete
    }

    /// The decision matrix (paged-loading-plan.md §2.4, rows 1–5).
    public static func nextAction(
        isIncremental: Bool,
        state: LoaderState?,
        planFingerprint: UInt64,
        totalEntries: Int64
    ) -> Action {
        // Row 1 — the system store is empty regardless of what the cursor claims
        // (first enable from Settings, restore, store purge, post-failure rebuild).
        guard isIncremental else { return .emitFirstPage }
        // Rows 2 & 3 — no cursor, or a cursor for a different plan.
        guard let state, state.planFingerprint == planFingerprint else {
            return .restartAndEmitFirstPage
        }
        // Row 5 — nothing to do.
        if state.entriesLoaded >= totalEntries { return .alreadyComplete }
        // Row 4 — the normal driving loop.
        return .emitPage(startIndex: state.entriesLoaded)
    }

    /// Reload rounds a full load needs — the app bounds its driving loop with this
    /// plus a safety margin.
    public static func pageCount(totalEntries: Int64, pageSize: Int64 = pageSize) -> Int {
        guard totalEntries > 0, pageSize > 0 else { return 0 }
        return Int((totalEntries + pageSize - 1) / pageSize)
    }
}
