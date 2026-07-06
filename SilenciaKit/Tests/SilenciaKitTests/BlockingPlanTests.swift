@testable import SilenciaKit
import XCTest

final class BlockingPlanTests: XCTestCase {
    // MARK: Run coalescing

    func testCoalesceMergesOverlappingAndAdjacentRuns() {
        let runs = [
            BlockingRun(base: 0, count: 10), // 0...9
            BlockingRun(base: 5, count: 10), // 5...14  (overlaps)
            BlockingRun(base: 15, count: 5), // 15...19 (adjacent to previous end 14)
            BlockingRun(base: 100, count: 1) // isolated
        ]
        let merged = BlockingRunMerger.coalesce(runs)
        XCTAssertEqual(merged, [
            BlockingRun(base: 0, count: 20), // 0...19 fused
            BlockingRun(base: 100, count: 1)
        ])
    }

    func testCoalesceIsIdempotentAndSorted() {
        let runs = [
            BlockingRun(base: 300, count: 2),
            BlockingRun(base: 10, count: 2),
            BlockingRun(base: 200, count: 2)
        ]
        let merged = BlockingRunMerger.coalesce(runs)
        XCTAssertEqual(merged.map(\.base), [10, 200, 300])
        XCTAssertEqual(BlockingRunMerger.coalesce(merged), merged)
    }

    // MARK: Streaming invariants (the memory-critical core)

    func testNumbersAreStrictlyAscendingAndComplete() {
        let plan = BlockingPlan(runs: [
            BlockingRun(base: 1000, count: 3),
            BlockingRun(base: 5000, count: 2)
        ])
        let emitted = Array(plan.numbers)
        XCTAssertEqual(emitted, [1000, 1001, 1002, 5000, 5001])
        // Strictly ascending — the invariant CallKit requires.
        XCTAssertEqual(emitted, emitted.sorted())
        XCTAssertEqual(Set(emitted).count, emitted.count, "no duplicates")
        XCTAssertEqual(Int64(emitted.count), plan.totalEntries)
    }

    func testUserNumberInsideArcepRangeIsAbsorbedNotDuplicated() {
        // A custom number that already sits inside "33162" must not be emitted twice.
        let arcep = [ArcepRange(prefix: "33162", label: "01 62")]
        let dupe = BlockingRun(base: 33_162_000_500, count: 1) // inside 33162 range
        let plan = BlockingPlan(arcepRanges: arcep, userRuns: [dupe])
        XCTAssertEqual(plan.runs.count, 1)
        XCTAssertEqual(plan.totalEntries, 1_000_000, "no double-count")
    }

    func testUserNumberOutsideRangesAddsEntry() {
        let arcep = [ArcepRange(prefix: "33162", label: "01 62")]
        let extra = BlockingRun(base: 33_612_345_678, count: 1) // a mobile, outside any range
        let plan = BlockingPlan(arcepRanges: arcep, userRuns: [extra])
        XCTAssertEqual(plan.runs.count, 2)
        XCTAssertEqual(plan.totalEntries, 1_000_001)
    }

    func testLargeStreamStaysStrictlyAscendingWithConstantMemory() {
        // Two full 1,000,000 Arcep ranges = 2,000,000 entries. We stream them and
        // only ever hold the previous value — proving O(1)-memory iteration works
        // at the real scale the extension faces.
        let plan = BlockingPlan(arcepRanges: [
            ArcepRange(prefix: "33948", label: "09 48"),
            ArcepRange(prefix: "33949", label: "09 49")
        ])
        XCTAssertEqual(plan.totalEntries, 2_000_000)

        var previous: Int64 = .min
        var count: Int64 = 0
        for number in plan.numbers {
            XCTAssertGreaterThan(number, previous, "stream must be strictly ascending")
            previous = number
            count += 1
        }
        XCTAssertEqual(count, 2_000_000)
        XCTAssertEqual(previous, 33_949_999_999) // last number of the 09 49 range
    }

    // MARK: Plan fingerprint (cross-process identity of the loaded plan)

    func testFingerprintStableAcrossEquivalentPlans() {
        let fromRanges = BlockingPlan(arcepRanges: RangeData.bundledDefault.ranges)
        let fromRuns = BlockingPlan(runs: RangeData.bundledDefault.ranges.compactMap(\.run).reversed())
        XCTAssertEqual(
            fromRanges.fingerprint,
            fromRuns.fingerprint,
            "fingerprint must be order-independent after coalesce"
        )
    }

    func testFingerprintChangesWhenPlanChanges() {
        let base = BlockingPlan(arcepRanges: [ArcepRange(prefix: "33948", label: "09 48")])
        let bigger = BlockingPlan(
            arcepRanges: [ArcepRange(prefix: "33948", label: "09 48")],
            userRuns: [BlockingRun(base: 33_612_345_678, count: 1)]
        )
        XCTAssertNotEqual(base.fingerprint, bigger.fingerprint)
    }

    func testFingerprintKnownValue() {
        // Pins the FNV-1a algorithm to a precomputed constant: the app and the
        // extension compare fingerprints across processes, so the value can never
        // drift silently (Swift's `Hasher` is per-process seeded and was replaced
        // for exactly this reason). Reference: FNV-1a(64) over the little-endian
        // bytes of Int64(1) then Int64(2).
        let plan = BlockingPlan(runs: [BlockingRun(base: 1, count: 2)])
        XCTAssertEqual(plan.fingerprint, 0x7717_9803_63C8_E066)
    }
}
