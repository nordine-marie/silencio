import XCTest
@testable import SilenciaKit

final class RangeDataTests: XCTestCase {
    func testBundledDefaultIsValidAndCoversTwelveMillion() throws {
        let data = RangeData.bundledDefault
        XCTAssertNoThrow(try data.validate())
        XCTAssertEqual(data.ranges.count, 12)
        XCTAssertEqual(data.totalNumbersCovered, 12_000_000)
    }

    func testBundledJSONResourceMatchesDefault() {
        // Proves the shipped ranges.json parses, validates, and agrees with the code.
        let loaded = RangeData.loadBundled()
        XCTAssertEqual(loaded.ranges, RangeData.bundledDefault.ranges)
    }

    func testValidationRejectsMalformedPrefix() {
        let bad = RangeData(version: 1, updated: "2026-01-01", ranges: [
            ArcepRange(prefix: "3316", label: "bad"), // only 4 digits
        ])
        XCTAssertThrowsError(try bad.validate()) { error in
            XCTAssertEqual(error as? RangeData.ValidationError, .malformedPrefix("3316"))
        }
    }

    func testValidationRejectsOverlappingRanges() {
        // Two identical prefixes overlap.
        let bad = RangeData(version: 1, updated: "2026-01-01", ranges: [
            ArcepRange(prefix: "33162", label: "01 62"),
            ArcepRange(prefix: "33162", label: "dup"),
        ])
        XCTAssertThrowsError(try bad.validate())
    }

    func testValidationRejectsEmpty() {
        let empty = RangeData(version: 1, updated: "2026-01-01", ranges: [])
        XCTAssertThrowsError(try empty.validate()) { error in
            XCTAssertEqual(error as? RangeData.ValidationError, .emptyRanges)
        }
    }

    func testArcepRangeBaseAndRun() {
        let r = ArcepRange(prefix: "33948", label: "09 48")
        XCTAssertEqual(r.base, 33_948_000_000)
        XCTAssertEqual(r.run, BlockingRun(base: 33_948_000_000, count: 1_000_000))
    }
}
