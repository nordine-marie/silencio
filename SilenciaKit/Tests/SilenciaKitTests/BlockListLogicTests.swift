@testable import SilenciaKit
import XCTest

final class BlockListLogicTests: XCTestCase {
    private let ranges = RangeData.bundledDefault.ranges

    private func add(
        _ raw: String,
        existing: [BlockEntry] = []
    ) -> BlockListLogic.AddOutcome {
        BlockListLogic.evaluateAdd(raw: raw, existing: existing, arcepRanges: ranges)
    }

    func testValidNewNumberIsAdded() {
        guard case let .added(entry) = add("06 12 34 56 78") else {
            return XCTFail("expected .added")
        }
        XCTAssertEqual(entry.run, BlockingRun(base: 33_612_345_678, count: 1))
    }

    func testGarbageIsInvalid() {
        XCTAssertEqual(add("n'importe quoi"), .invalid)
    }

    func testOverbroadUncoveredPrefixIsTooBroad() {
        // "05 5" spans 10^7 numbers and no Arcep range covers it.
        XCTAssertEqual(add("05 5"), .tooBroad)
        // A 5-national-digit prefix (10^4) is within the span budget.
        guard case .added = add("05 55 12") else {
            return XCTFail("10^4-span prefix should be addable")
        }
    }

    func testNumberInsideArcepRangeIsAlreadyCovered() {
        // 01 62 xx xx xx sits inside the "01 62" Arcep range.
        XCTAssertEqual(add("01 62 34 56 78"), .alreadyCovered(rangeLabel: "01 62"))
        // A whole prefix inside a range is covered too (the design's example).
        XCTAssertEqual(add("01 62"), .alreadyCovered(rangeLabel: "01 62"))
    }

    func testExactAndSubsumedDuplicatesAreRejected() throws {
        let existing = try [XCTUnwrap(BlockEntry(raw: "08 99 70"))] // covers 33899700000..33899709999
        XCTAssertEqual(add("08 99 70", existing: existing), .duplicate)
        XCTAssertEqual(add("08 99 70 11 22", existing: existing), .duplicate)
        // A sibling prefix outside the span is NOT a duplicate.
        guard case .added = add("08 99 71", existing: existing) else {
            return XCTFail("sibling prefix should be addable")
        }
    }

    func testManyEntriesAreAllowed_NoTierLimit() {
        // Paid upfront: no per-count gating; only the memory budget bounds the list.
        let fifty = (10 ..< 60).map { BlockEntry(raw: "06 12 34 56 \($0)")! }
        guard case .added = add("07 98 76 54 32", existing: fifty) else {
            return XCTFail("entry count alone must never block an add")
        }
    }

    func testBudgetCapBlocksRunawayPrefixTotals() {
        // 50 prefixes × 10,000 numbers exhaust the 500k budget exactly.
        let fifty = (10 ..< 60).map { BlockEntry(raw: "0899\($0)")! }
        XCTAssertEqual(fifty.reduce(Int64(0)) { $0 + $1.run.count }, BlockListLogic.customEntryBudget)
        XCTAssertEqual(add("089960", existing: fifty), .budgetExceeded)
        // A single number still doesn't fit — budget is by expanded count.
        XCTAssertEqual(add("06 12 34 56 78", existing: fifty), .budgetExceeded)
    }

    func testPrecedence_CoveredBeatsDuplicateAndBudget() {
        // Covered input reports covered even when the budget is exhausted.
        let fifty = (10 ..< 60).map { BlockEntry(raw: "0899\($0)")! }
        XCTAssertEqual(
            add("01 63 00 00 00", existing: fifty),
            .alreadyCovered(rangeLabel: "01 63")
        )
    }
}
