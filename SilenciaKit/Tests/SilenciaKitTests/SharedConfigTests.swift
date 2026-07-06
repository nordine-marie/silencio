@testable import SilenciaKit
import XCTest

final class SharedConfigTests: XCTestCase {
    func testPlanCoversEveryRangePlusUserEntries() throws {
        let entry = try XCTUnwrap(BlockEntry(raw: "06 12 34 56 78")) // a custom mobile
        let config = SharedConfig(rangeData: .bundledDefault, userEntries: [entry])
        // Paid upfront: every install blocks all 12 ranges + the custom number.
        XCTAssertEqual(config.plan().totalEntries, 12_000_001)
    }

    func testPlanCoversEverythingWithNoUserEntries() {
        let config = SharedConfig(rangeData: .bundledDefault)
        XCTAssertEqual(config.plan().totalEntries, 12_000_000)
    }

    func testUserPrefixEntryExpandsInPlan() throws {
        let config = try SharedConfig(
            rangeData: .bundledDefault,
            userEntries: [XCTUnwrap(BlockEntry(raw: "08 99 70"))] // 10,000-number span
        )
        XCTAssertEqual(config.plan().totalEntries, 12_010_000)
    }

    func testConfigRoundTripsThroughCodable() throws {
        let config = try SharedConfig(
            rangeData: .bundledDefault,
            userEntries: [XCTUnwrap(BlockEntry(raw: "06 12 34 56 78"))]
        )
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SharedConfig.self, from: data)
        XCTAssertEqual(decoded, config)
    }
}
