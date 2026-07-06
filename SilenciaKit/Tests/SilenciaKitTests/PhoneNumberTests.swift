import XCTest
@testable import SilenciaKit

final class PhoneNumberTests: XCTestCase {
    func testNormalizesCommonFrenchFormats() {
        let expected: Int64 = 33_612_345_678
        XCTAssertEqual(PhoneNumber.normalizeFR("0612345678"), expected)
        XCTAssertEqual(PhoneNumber.normalizeFR("06 12 34 56 78"), expected)
        XCTAssertEqual(PhoneNumber.normalizeFR("06.12.34.56.78"), expected)
        XCTAssertEqual(PhoneNumber.normalizeFR("+33612345678"), expected)
        XCTAssertEqual(PhoneNumber.normalizeFR("+33 6 12 34 56 78"), expected)
        XCTAssertEqual(PhoneNumber.normalizeFR("0033612345678"), expected)
    }

    func testNormalizesLandlineInsideArcepRange() {
        // 01 62 00 00 00 -> falls exactly on the base of the "33162" Arcep range.
        XCTAssertEqual(PhoneNumber.normalizeFR("01 62 00 00 00"), 33_162_000_000)
    }

    func testRejectsMalformedNumbers() {
        XCTAssertNil(PhoneNumber.normalizeFR(""))
        XCTAssertNil(PhoneNumber.normalizeFR("061234567"))     // too short
        XCTAssertNil(PhoneNumber.normalizeFR("06123456789"))   // too long
        XCTAssertNil(PhoneNumber.normalizeFR("abcdefghij"))
        XCTAssertNil(PhoneNumber.normalizeFR("1234"))
        XCTAssertNil(PhoneNumber.normalizeFR("+441632960000")) // non-FR country code
    }

    func testNormalizePrefixAtMaxSpan() {
        // "06 12 34" keeps 5 NSN digits -> 4 trailing digits -> 10,000 numbers (the cap).
        let run = PhoneNumber.normalizePrefixFR("06 12 34")
        XCTAssertEqual(run, BlockingRun(base: 33_612_340_000, count: 10_000))
    }

    func testNormalizePrefixSmallerSpan() {
        // "06 12 34 5" keeps 6 NSN digits -> 3 trailing digits -> 1,000 numbers.
        let run = PhoneNumber.normalizePrefixFR("06 12 34 5")
        XCTAssertEqual(run, BlockingRun(base: 33_612_345_000, count: 1_000))
    }

    func testRejectsPrefixExceedingSpanCap() {
        // "06 12 3" keeps 4 NSN digits -> 5 trailing digits (100,000) -> over the cap.
        XCTAssertNil(PhoneNumber.normalizePrefixFR("06 12 3"))
    }

    func testFullNumberIsPrefixWithSpanOne() {
        let run = PhoneNumber.normalizePrefixFR("06 12 34 56 78")
        XCTAssertEqual(run?.count, 1)
        XCTAssertEqual(run?.base, PhoneNumber.normalizeFR("0612345678"))
    }
}
