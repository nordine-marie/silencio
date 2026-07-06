import Foundation

/// Turns the paged loader's coarse, bursty progress into smooth, continuous
/// on-screen motion.
///
/// The real cursor (`LoaderState.progress`) only advances once per reload round,
/// and each round emits a whole ≤1.8M-entry page (`PagedLoader.pageSize`). Against
/// a 12M / 12-range plan that's ~1.8 range-bricks landing at once, then a multi-
/// second pause while the next page loads — the bar lurches instead of filling.
///
/// This eases a *displayed* fraction toward the real `target` every frame:
///
///  - **Continuous** — it approaches the target asymptotically, so between rounds
///    it keeps drifting up (decelerating) instead of freezing dead.
///  - **Uniform** — a velocity cap tames the surge right after a coarse cursor
///    jump, so the bar fills at an even pace rather than in bursts.
///  - **Honest** — `displayed` never passes `target`, so a full brick still means
///    that range is genuinely blocked already, and it never moves backward.
///
/// Pure value type: the view owns one, feeds it the real fraction and a per-frame
/// time delta, and draws `displayed`. Tested headless in `SmoothedProgressTests`.
public struct SmoothedProgress: Equatable, Sendable {
    /// The fraction to draw, 0…1.
    public private(set) var displayed: Double
    /// The latest real fraction reported by the loader cursor, 0…1.
    public private(set) var target: Double

    /// How fast the displayed value closes the remaining gap, per second. The gap
    /// left after `dt` seconds is `gap · e^(-responsiveness · dt)`, so a larger
    /// value tracks the cursor more tightly; a smaller one glides more.
    public static let responsiveness: Double = 0.8

    /// Ceiling on fill speed (fraction per second). Caps the burst right after a
    /// coarse cursor jump so motion stays even — one full bar in ≳1/maxFillRate s.
    public static let maxFillRate: Double = 0.07

    public init(displayed: Double = 0, target: Double = 0) {
        let start = Self.clamp(displayed)
        self.displayed = start
        self.target = max(start, Self.clamp(target))
    }

    /// Record a new real fraction from the loader cursor. Monotonic: the target
    /// never drops, so a stale/rounded reread can't rewind the bar.
    public mutating func retarget(to fraction: Double) {
        target = max(target, Self.clamp(fraction))
    }

    /// Advance `displayed` toward `target` after `dt` seconds. Eases in (surge
    /// after a jump is capped) and eases out (asymptotic near the target); never
    /// overshoots, never moves backward.
    public mutating func advance(by dt: Double) {
        guard dt > 0, displayed < target else { return }
        let gap = target - displayed
        let eased = gap * (1 - exp(-Self.responsiveness * dt))
        let step = min(eased, Self.maxFillRate * dt)
        displayed = min(target, displayed + step)
    }

    /// Snap straight to done — the load finished, so fill the last sliver at once.
    public mutating func finish() {
        target = 1
        displayed = 1
    }

    private static func clamp(_ x: Double) -> Double {
        min(1, max(0, x))
    }
}
