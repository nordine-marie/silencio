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

    /// A stable content fingerprint so the app (driver) and the extension (streamer)
    /// can agree on which plan a persisted `LoaderState` cursor refers to
    /// (paged-loading-plan.md §2.3). FNV-1a over the canonical (sorted, disjoint)
    /// runs — deterministic across processes and launches, unlike `Hasher`, which
    /// is randomly seeded per process and must never cross a process boundary.
    public var fingerprint: UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325 // FNV-1a 64-bit offset basis
        func mix(_ value: Int64) {
            var bytes = UInt64(bitPattern: value)
            for _ in 0 ..< 8 {
                hash = (hash ^ (bytes & 0xFF)) &* 0x0000_0100_0000_01B3 // FNV-1a prime
                bytes >>= 8
            }
        }
        for run in runs {
            mix(run.base)
            mix(run.count)
        }
        return hash
    }

    /// The lazily-generated, strictly-ascending sequence of every number to block.
    /// **Constant memory** regardless of `totalEntries`: it walks runs and offsets,
    /// never allocating an array.
    public var numbers: BlockingNumberSequence {
        BlockingNumberSequence(runs: runs, startIndex: 0, maxCount: .max)
    }

    /// One page of the canonical stream: entries `[startIndex, startIndex + maxCount)`
    /// (paged-loading-plan.md §2.5). This is what the extension feeds to CallKit —
    /// the system caps every `beginRequest` at 2M entries, so the full stream is
    /// loaded as successive pages across app-driven reload rounds. Positioning skips
    /// whole runs (pure count arithmetic); iteration stays O(1) memory.
    public func pageNumbers(startIndex: Int64, maxCount: Int64) -> BlockingNumberSequence {
        BlockingNumberSequence(runs: runs, startIndex: startIndex, maxCount: maxCount)
    }
}

/// A `Sequence` that yields blocked numbers in strictly ascending order using
/// O(1) memory. Safe to iterate over 12,000,000+ entries inside the extension.
public struct BlockingNumberSequence: Sequence, Sendable {
    let runs: [BlockingRun]
    let startIndex: Int64
    let maxCount: Int64

    public func makeIterator() -> Iterator {
        Iterator(runs: runs, startIndex: startIndex, maxCount: maxCount)
    }

    public struct Iterator: IteratorProtocol {
        private let runs: [BlockingRun]
        private var runIndex = 0
        private var offset: Int64 = 0
        private var remaining: Int64

        init(runs: [BlockingRun], startIndex: Int64, maxCount: Int64) {
            self.runs = runs
            remaining = Swift.max(0, maxCount)
            // Position at the startIndex-th entry of the canonical stream by
            // skipping whole runs — no per-entry iteration.
            var toSkip = Swift.max(0, startIndex)
            while runIndex < runs.count, toSkip >= runs[runIndex].count {
                toSkip -= runs[runIndex].count
                runIndex += 1
            }
            offset = toSkip
        }

        public mutating func next() -> Int64? {
            guard remaining > 0 else { return nil }
            while runIndex < runs.count {
                let run = runs[runIndex]
                if offset < run.count {
                    let value = run.base + offset
                    offset += 1
                    remaining -= 1
                    return value
                }
                runIndex += 1
                offset = 0
            }
            return nil
        }
    }
}
