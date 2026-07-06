import Foundation

/// The complete, validated description of what to block, assembled in the main app
/// and consumed by the extension. Holds only the (small) set of coalesced runs —
/// never the expanded numbers.
public struct BlockingPlan: Equatable, Sendable {
    /// Disjoint, strictly-ascending runs. Invariant guaranteed by ``init``.
    public let runs: [BlockingRun]

    /// Builds a plan from active Arcep ranges plus user entries, coalescing
    /// everything into disjoint ascending runs. User entries already covered by an
    /// Arcep range are absorbed (the "déjà couvert ✅" case) rather than duplicated.
    public init(arcepRanges: [ArcepRange], userRuns: [BlockingRun] = []) {
        let arcepRuns = arcepRanges.compactMap(\.run)
        runs = BlockingRunMerger.coalesce(arcepRuns + userRuns)
    }

    /// Direct initializer for pre-coalesced runs (used by the extension after it
    /// reads a persisted plan). Re-coalesces defensively.
    public init(runs: [BlockingRun]) {
        self.runs = BlockingRunMerger.coalesce(runs)
    }

    /// Total blocking entries this plan will emit (e.g. 12,000,000).
    public var totalEntries: Int64 {
        runs.reduce(0) { $0 + $1.count }
    }

    /// A stable content hash so the extension can decide full-reload vs incremental
    /// (see implementation-plan.md §2.4). Order-independent-safe because `runs` is
    /// already canonicalized (sorted + disjoint).
    public var stateHash: Int {
        var hasher = Hasher()
        for run in runs {
            hasher.combine(run.base)
            hasher.combine(run.count)
        }
        return hasher.finalize()
    }

    /// The lazily-generated, strictly-ascending sequence of every number to block.
    /// **Constant memory** regardless of `totalEntries`: it walks runs and offsets,
    /// never allocating an array. This is what the extension feeds to CallKit.
    public var numbers: BlockingNumberSequence {
        BlockingNumberSequence(runs: runs)
    }
}

/// A `Sequence` that yields every blocked number in strictly ascending order using
/// O(1) memory. Safe to iterate over 12,000,000+ entries inside the extension.
public struct BlockingNumberSequence: Sequence, Sendable {
    let runs: [BlockingRun]

    public func makeIterator() -> Iterator {
        Iterator(runs: runs)
    }

    public struct Iterator: IteratorProtocol {
        private let runs: [BlockingRun]
        private var runIndex = 0
        private var offset: Int64 = 0

        init(runs: [BlockingRun]) {
            self.runs = runs
        }

        public mutating func next() -> Int64? {
            while runIndex < runs.count {
                let run = runs[runIndex]
                if offset < run.count {
                    let value = run.base + offset
                    offset += 1
                    return value
                }
                runIndex += 1
                offset = 0
            }
            return nil
        }
    }
}
