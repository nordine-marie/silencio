@testable import SilenciaKit
import XCTest

final class BlockEntryTests: XCTestCase {
    func testParsesFullNumberInCommonFormats() {
        for raw in ["0612345678", "06 12 34 56 78", "06.12.34.56.78", "+33612345678", "0033 6 12 34 56 78"] {
            let entry = BlockEntry(raw: raw)
            XCTAssertEqual(entry?.kind, .number, "failed for \(raw)")
            XCTAssertEqual(entry?.run, BlockingRun(base: 33_612_345_678, count: 1), "failed for \(raw)")
            XCTAssertEqual(entry?.nationalDigits, "612345678")
            XCTAssertEqual(entry?.display, "06 12 34 56 78")
        }
    }

    func testParsesPrefixIntoBoundedRun() {
        let entry = BlockEntry(raw: "08 99 70")
        XCTAssertEqual(entry?.kind, .prefix)
        // "899 70" leaves 4 free digits → span of 10,000 numbers.
        XCTAssertEqual(entry?.run, BlockingRun(base: 33_899_700_000, count: 10000))
        XCTAssertEqual(entry?.nationalDigits, "89970")
        XCTAssertEqual(entry?.display, "08 99 70")
    }

    func testPrefixDisplayGroupsPairsWithTrailingOddDigit() {
        let entry = BlockEntry(raw: "0948 112")
        XCTAssertEqual(entry?.run, BlockingRun(base: 33_948_112_000, count: 1000))
        XCTAssertEqual(entry?.display, "09 48 11 2")
    }

    func testRelaxedSpanParsesBroadPrefixesForCoverageProbing() {
        // Default budget rejects a whole-range prefix…
        XCTAssertNil(BlockEntry(raw: "01 62"))
        // …but the relaxed parse (used by BlockListLogic) accepts it.
        let probe = BlockEntry(raw: "01 62", maxSpanDigits: 8)
        XCTAssertEqual(probe?.run, BlockingRun(base: 33_162_000_000, count: 1_000_000))
        XCTAssertEqual(probe?.display, "01 62")
    }

    func testRejectsGarbageAndOverbroadPrefixes() {
        XCTAssertNil(BlockEntry(raw: ""))
        XCTAssertNil(BlockEntry(raw: "hello"))
        XCTAssertNil(BlockEntry(raw: "12345")) // no trunk 0 / +33 → ambiguous
        XCTAssertNil(BlockEntry(raw: "06")) // span 10^8 — over the 10^4 budget
        XCTAssertNil(BlockEntry(raw: "00 12 34 56 78")) // NSN can't start with 0
    }

    func testRoundTripsThroughCodable() throws {
        let entry = try XCTUnwrap(BlockEntry(raw: "09 48 70 11 22"))
        let decoded = try JSONDecoder().decode(BlockEntry.self, from: JSONEncoder().encode(entry))
        XCTAssertEqual(decoded, entry)
        XCTAssertEqual(decoded.display, entry.display)
    }

    func testIdIsStablePerKindAndDigits() {
        XCTAssertEqual(BlockEntry(raw: "0612345678")?.id, BlockEntry(raw: "+33 6 12 34 56 78")?.id)
        XCTAssertNotEqual(BlockEntry(raw: "0948 70")?.id, BlockEntry(raw: "0948 71")?.id)
    }
}
