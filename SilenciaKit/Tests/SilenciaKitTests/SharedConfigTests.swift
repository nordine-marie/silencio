import XCTest
@testable import SilenciaKit

final class SharedConfigTests: XCTestCase {
    func testFreeConfigPlanGatesToSampleRangesPlusUserRuns() {
        let userRun = BlockingRun(base: 33_612_345_678, count: 1) // a custom mobile
        let config = SharedConfig(tier: .free, rangeData: .bundledDefault, userRuns: [userRun])
        let plan = config.plan()
        // 2 free ranges (2,000,000) + 1 custom number, none overlapping.
        XCTAssertEqual(plan.totalEntries, 2_000_001)
    }

    func testLifetimeConfigPlanCoversEverything() {
        let config = SharedConfig(tier: .lifetime, rangeData: .bundledDefault)
        XCTAssertEqual(config.plan().totalEntries, 12_000_000)
    }

    func testConfigRoundTripsThroughCodable() throws {
        let config = SharedConfig(
            tier: .lifetime,
            rangeData: .bundledDefault,
            userRuns: [BlockingRun(base: 33_612_345_678, count: 1)]
        )
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SharedConfig.self, from: data)
        XCTAssertEqual(decoded, config)
    }
}
