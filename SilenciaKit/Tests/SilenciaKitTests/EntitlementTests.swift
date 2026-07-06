import XCTest
@testable import SilenciaKit

final class EntitlementTests: XCTestCase {
    func testFreeTierBlocksOnlyTheTwoSampleRanges() {
        let active = Entitlement.activeRanges(from: RangeData.bundledDefault.ranges, tier: .free)
        XCTAssertEqual(Set(active.map(\.label)), ["09 48", "09 49"])
        // Free tier proves the mechanism: 2,000,000 numbers.
        let plan = BlockingPlan(arcepRanges: active)
        XCTAssertEqual(plan.totalEntries, 2_000_000)
    }

    func testLifetimeTierBlocksEverything() {
        let active = Entitlement.activeRanges(from: RangeData.bundledDefault.ranges, tier: .lifetime)
        XCTAssertEqual(active.count, 12)
        XCTAssertEqual(BlockingPlan(arcepRanges: active).totalEntries, 12_000_000)
    }

    func testCustomEntryLimits() {
        XCTAssertEqual(Entitlement.customEntryLimit(tier: .free), 5)
        XCTAssertEqual(Entitlement.customEntryLimit(tier: .lifetime), .max)
    }
}
