@testable import SilenciaKit
import XCTest

/// Guards the paged-loading core (paged-loading-plan.md): the decision matrix,
/// page extraction, and the cursor codec. This logic is what keeps the extension
/// under CallKit's 2M-entries-per-request cap while still loading all 12M.
final class PagedLoaderTests: XCTestCase {
    // MARK: Decision matrix (§2.4, rows 1–5)

    private let fingerprint: UInt64 = 0xDEAD_BEEF
    private let total: Int64 = 12_000_000

    func testRow1_NonIncrementalAlwaysStartsFromScratch() {
        // Even a valid-looking cursor is meaningless when the store is empty.
        let staleState = LoaderState(
            planFingerprint: fingerprint, entriesLoaded: 5_400_000, totalEntries: total
        )
        for state in [nil, staleState] {
            XCTAssertEqual(
                PagedLoader.nextAction(
                    isIncremental: false, state: state,
                    planFingerprint: fingerprint, totalEntries: total
                ),
                .emitFirstPage
            )
        }
    }

    func testRow2_MissingStateRestarts() {
        XCTAssertEqual(
            PagedLoader.nextAction(
                isIncremental: true, state: nil,
                planFingerprint: fingerprint, totalEntries: total
            ),
            .restartAndEmitFirstPage
        )
    }

    func testRow3_PlanChangeRestarts() {
        let state = LoaderState(
            planFingerprint: 0x0BAD_F00D, entriesLoaded: total, totalEntries: total
        )
        XCTAssertEqual(
            PagedLoader.nextAction(
                isIncremental: true, state: state,
                planFingerprint: fingerprint, totalEntries: total
            ),
            .restartAndEmitFirstPage,
            "a complete load of a *different* plan must still be rebuilt"
        )
    }

    func testRow4_IncompleteStateContinuesFromCursor() {
        let state = LoaderState(
            planFingerprint: fingerprint, entriesLoaded: 3_600_000, totalEntries: total
        )
        XCTAssertEqual(
            PagedLoader.nextAction(
                isIncremental: true, state: state,
                planFingerprint: fingerprint, totalEntries: total
            ),
            .emitPage(startIndex: 3_600_000)
        )
    }

    func testRow5_CompleteStateDoesNothing() {
        let state = LoaderState(
            planFingerprint: fingerprint, entriesLoaded: total, totalEntries: total
        )
        XCTAssertEqual(
            PagedLoader.nextAction(
                isIncremental: true, state: state,
                planFingerprint: fingerprint, totalEntries: total
            ),
            .alreadyComplete
        )
    }

    // MARK: Page extraction (§2.5)

    func testPagesConcatenateToTheFullStream() {
        // Runs engineered so pages end mid-run, at run edges, and past the end.
        let plan = BlockingPlan(runs: [
            BlockingRun(base: 100, count: 7),
            BlockingRun(base: 500, count: 3),
            BlockingRun(base: 900, count: 5)
        ])
        let full = Array(plan.numbers)
        XCTAssertEqual(full.count, 15)

        for pageSize in Int64(1) ... 16 {
            var concatenated: [Int64] = []
            var start: Int64 = 0
            while start < plan.totalEntries {
                let page = Array(plan.pageNumbers(startIndex: start, maxCount: pageSize))
                XCTAssertLessThanOrEqual(Int64(page.count), pageSize)
                XCTAssertEqual(page, page.sorted(), "each page is ascending")
                concatenated += page
                start += Int64(page.count)
            }
            XCTAssertEqual(concatenated, full, "pageSize \(pageSize) must tile the stream exactly")
        }
    }

    func testPageResumesMidRun() {
        let plan = BlockingPlan(runs: [BlockingRun(base: 1000, count: 10)])
        XCTAssertEqual(
            Array(plan.pageNumbers(startIndex: 4, maxCount: 3)),
            [1004, 1005, 1006]
        )
    }

    func testPageSpansRunBoundary() {
        let plan = BlockingPlan(runs: [
            BlockingRun(base: 10, count: 3), // entries 0–2
            BlockingRun(base: 50, count: 3) // entries 3–5
        ])
        XCTAssertEqual(
            Array(plan.pageNumbers(startIndex: 2, maxCount: 3)),
            [12, 50, 51]
        )
    }

    func testPageStartingExactlyAtRunEdge() {
        let plan = BlockingPlan(runs: [
            BlockingRun(base: 10, count: 3),
            BlockingRun(base: 50, count: 3)
        ])
        XCTAssertEqual(
            Array(plan.pageNumbers(startIndex: 3, maxCount: 10)),
            [50, 51, 52],
            "cursor at a run edge starts the next run, and the final page is partial"
        )
    }

    func testPagePastTheEndIsEmpty() {
        let plan = BlockingPlan(runs: [BlockingRun(base: 10, count: 3)])
        XCTAssertEqual(Array(plan.pageNumbers(startIndex: 3, maxCount: 5)), [])
        XCTAssertEqual(Array(plan.pageNumbers(startIndex: 99, maxCount: 5)), [])
        XCTAssertEqual(Array(plan.pageNumbers(startIndex: 0, maxCount: 0)), [])
    }

    func testFullBundledPlanTilesInSevenPagesUnderTheSystemCap() {
        // The real dataset: 12 Arcep ranges, 12M entries, the actual page size.
        let plan = BlockingPlan(arcepRanges: RangeData.bundledDefault.ranges)
        XCTAssertEqual(
            PagedLoader.pageCount(totalEntries: plan.totalEntries), 7,
            "12M at 1.8M/page is 7 rounds"
        )

        var start: Int64 = 0
        var previous: Int64 = .min
        var grandTotal: Int64 = 0
        var pages = 0
        while start < plan.totalEntries {
            var pageCount: Int64 = 0
            for number in plan.pageNumbers(startIndex: start, maxCount: PagedLoader.pageSize) {
                XCTAssertGreaterThan(number, previous, "globally ascending across pages")
                previous = number
                pageCount += 1
            }
            XCTAssertLessThanOrEqual(
                pageCount, PagedLoader.systemMaxEntriesPerRequest,
                "every page must respect the per-request cap"
            )
            grandTotal += pageCount
            start += pageCount
            pages += 1
        }
        XCTAssertEqual(grandTotal, 12_000_000)
        XCTAssertEqual(pages, 7)
        XCTAssertEqual(previous, 33_949_999_999)
    }

    // MARK: LoaderState codec & semantics

    func testLoaderStateRoundTripsThroughJSON() throws {
        let state = LoaderState(
            planFingerprint: .max, entriesLoaded: 3_600_000, totalEntries: 12_000_000
        )
        let decoded = try JSONDecoder().decode(
            LoaderState.self, from: JSONEncoder().encode(state)
        )
        XCTAssertEqual(decoded, state)
    }

    func testLoaderStateCompletionAndProgress() {
        var state = LoaderState(planFingerprint: 1, entriesLoaded: 6_000_000, totalEntries: 12_000_000)
        XCTAssertFalse(state.isComplete)
        XCTAssertEqual(state.progress, 0.5, accuracy: 0.0001)

        state.entriesLoaded = 12_000_000
        XCTAssertTrue(state.isComplete)
        XCTAssertEqual(state.progress, 1)

        let empty = LoaderState(planFingerprint: 1, entriesLoaded: 0, totalEntries: 0)
        XCTAssertTrue(empty.isComplete, "an empty plan is trivially complete")
        XCTAssertEqual(empty.progress, 1)
    }

    func testPageCountEdges() {
        XCTAssertEqual(PagedLoader.pageCount(totalEntries: 0), 0)
        XCTAssertEqual(PagedLoader.pageCount(totalEntries: 1), 1)
        XCTAssertEqual(PagedLoader.pageCount(totalEntries: PagedLoader.pageSize), 1)
        XCTAssertEqual(PagedLoader.pageCount(totalEntries: PagedLoader.pageSize + 1), 2)
    }

    func testPageSizeStaysUnderTheSystemCap() {
        XCTAssertLessThan(
            PagedLoader.pageSize, PagedLoader.systemMaxEntriesPerRequest,
            "headroom under the observed device cap is deliberate — never equal it"
        )
    }
}
