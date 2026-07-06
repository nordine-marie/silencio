@testable import SilenciaKit
import XCTest

/// Guards the display smoother that turns the paged loader's ~1.8M-per-round
/// cursor jumps into continuous, uniform bar motion — without ever letting the
/// bar claim more progress than the loader has actually confirmed.
final class SmoothedProgressTests: XCTestCase {
    // MARK: Invariants

    func testInitClampsAndKeepsTargetAtLeastDisplayed() {
        XCTAssertEqual(SmoothedProgress(displayed: -1).displayed, 0)
        XCTAssertEqual(SmoothedProgress(displayed: 2).displayed, 1)
        // A target below the start can't rewind the bar.
        let prog = SmoothedProgress(displayed: 0.5, target: 0.2)
        XCTAssertEqual(prog.target, 0.5)
        XCTAssertEqual(prog.displayed, 0.5)
    }

    func testNeverOvershootsTheTarget() {
        var prog = SmoothedProgress(displayed: 0, target: 0.15)
        // Even a huge time step lands exactly on the target, never past it.
        prog.advance(by: 1000)
        XCTAssertEqual(prog.displayed, 0.15, accuracy: 1e-9)
    }

    func testNeverMovesBackward() {
        var prog = SmoothedProgress()
        prog.retarget(to: 0.4)
        var last = prog.displayed
        for _ in 0 ..< 200 {
            prog.advance(by: 1.0 / 60.0)
            XCTAssertGreaterThanOrEqual(prog.displayed, last)
            last = prog.displayed
        }
    }

    func testRetargetIsMonotonic() {
        var prog = SmoothedProgress()
        prog.retarget(to: 0.6)
        prog.retarget(to: 0.3) // a stale reread must not pull the target down
        XCTAssertEqual(prog.target, 0.6)
        prog.retarget(to: 5) // clamps to 1
        XCTAssertEqual(prog.target, 1)
    }

    // MARK: Behaviour — continuous & uniform

    func testAdvanceIsANoOpWhenAlreadyAtTarget() {
        var prog = SmoothedProgress(displayed: 0.3, target: 0.3)
        prog.advance(by: 0.5)
        XCTAssertEqual(prog.displayed, 0.3)
    }

    func testAdvanceIgnoresNonPositiveDelta() {
        var prog = SmoothedProgress(displayed: 0, target: 1)
        prog.advance(by: 0)
        prog.advance(by: -0.1)
        XCTAssertEqual(prog.displayed, 0)
    }

    /// The point of the smoother: a single coarse cursor jump must not fill the
    /// whole page in one frame — the velocity cap spreads it over many frames.
    func testCoarseJumpIsSpreadAcrossFrames() {
        var prog = SmoothedProgress()
        prog.retarget(to: 0.15) // one page landed at once (1.8M / 12M)
        prog.advance(by: 1.0 / 60.0) // a single 60 fps frame
        // Cap is maxFillRate per second; one frame can't move more than that.
        XCTAssertLessThanOrEqual(prog.displayed, SmoothedProgress.maxFillRate / 60.0 + 1e-9)
        XCTAssertGreaterThan(prog.displayed, 0)
    }

    /// Between rounds the target is static, yet the bar must keep drifting up
    /// (decelerating) rather than freezing — that's what "continuous" means here.
    func testKeepsMovingBetweenCursorUpdates() {
        var prog = SmoothedProgress()
        prog.retarget(to: 0.3)
        prog.advance(by: 0.5)
        let mid = prog.displayed
        prog.advance(by: 0.5) // target unchanged, still must progress
        XCTAssertGreaterThan(prog.displayed, mid)
        XCTAssertLessThanOrEqual(prog.displayed, 0.3)
    }

    func testFinishSnapsToOne() {
        var prog = SmoothedProgress(displayed: 0.42, target: 0.42)
        prog.finish()
        XCTAssertEqual(prog.displayed, 1)
        XCTAssertEqual(prog.target, 1)
    }

    /// End to end: feed real cursor jumps like the sync loop does and step at
    /// 60 fps — the displayed value tracks up toward 1 and stays a valid fraction.
    func testTracksStepwiseCursorToCompletion() {
        var prog = SmoothedProgress()
        let cursorFractions = [0.15, 0.30, 0.45, 0.60, 0.75, 0.90, 1.0]
        for fraction in cursorFractions {
            prog.retarget(to: fraction)
            for _ in 0 ..< 180 { // ~3 s of frames per round
                prog.advance(by: 1.0 / 60.0)
                XCTAssertLessThanOrEqual(prog.displayed, prog.target)
                XCTAssertGreaterThanOrEqual(prog.displayed, 0)
            }
        }
        XCTAssertGreaterThan(prog.displayed, 0.9)
    }
}
