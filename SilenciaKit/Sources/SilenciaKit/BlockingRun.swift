import Foundation

/// A contiguous, ascending run of E.164 phone numbers to block, expressed as a
/// `base` and a `count` so it never has to be materialized as an array.
///
/// This is the unit the Call Directory extension streams to CallKit. Arcep ranges
/// expand to runs of 1,000,000; a single custom number is a run of `count == 1`;
/// a custom prefix is a run of `10^k`.
public struct BlockingRun: Equatable, Hashable, Sendable, Codable {
    public let base: Int64
    public let count: Int64

    public init(base: Int64, count: Int64) {
        precondition(count >= 1, "a blocking run must contain at least one number")
        self.base = base
        self.count = count
    }

    /// Inclusive last number in the run.
    public var upperBound: Int64 { base + count - 1 }

    public func contains(_ number: Int64) -> Bool {
        number >= base && number <= upperBound
    }
}

public enum BlockingRunMerger {
    /// Coalesces an arbitrary set of runs into the minimal set of **disjoint,
    /// strictly-ascending** runs covering exactly the same numbers.
    ///
    /// This is the small, cheap step (a few hundred runs at most) that guarantees
    /// the extension can then emit strictly ascending entries — CallKit rejects
    /// out-of-order or duplicate entries. Overlapping *and* adjacent runs are fused
    /// (e.g. `[0,1]` + `[1,2]` and `[0,1]` + `[2,3]` both fuse into one run).
    public static func coalesce(_ runs: [BlockingRun]) -> [BlockingRun] {
        guard !runs.isEmpty else { return [] }
        let sorted = runs.sorted { $0.base < $1.base }

        var result: [BlockingRun] = []
        var currentBase = sorted[0].base
        var currentEnd = sorted[0].upperBound // inclusive

        for run in sorted.dropFirst() {
            if run.base <= currentEnd + 1 {
                // Overlapping or adjacent: extend the current run.
                currentEnd = max(currentEnd, run.upperBound)
            } else {
                result.append(BlockingRun(base: currentBase, count: currentEnd - currentBase + 1))
                currentBase = run.base
                currentEnd = run.upperBound
            }
        }
        result.append(BlockingRun(base: currentBase, count: currentEnd - currentBase + 1))
        return result
    }
}
