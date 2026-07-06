import Foundation

/// Pure validation for the custom block list (F3, implementation-plan.md §3.3).
/// The UI calls ``evaluateAdd`` and renders the outcome; nothing here touches IO.
public enum BlockListLogic {
    /// Hard cap on the total numbers the custom list may expand to, protecting the
    /// extension memory budget (§3.3: "hard cap total custom-generated entries").
    public static let customEntryBudget: Int64 = 500_000

    /// Largest span a single custom prefix may cover (§3.3: ≤ 10,000 numbers).
    public static let maxPrefixSpan: Int64 = 10000

    public enum AddOutcome: Equatable, Sendable {
        /// Valid and new — persist it and reload the extension.
        case added(BlockEntry)
        /// Input is not a well-formed French number or prefix.
        case invalid
        /// Fully inside an Arcep range — the "déjà couvert ✅" case. The label is
        /// the covering range's French label (e.g. `"01 62"`).
        case alreadyCovered(rangeLabel: String)
        /// A well-formed prefix, but spanning more than ``maxPrefixSpan`` numbers
        /// and not inside an Arcep range — too broad to add.
        case tooBroad
        /// Already present in (or subsumed by) the user's own list.
        case duplicate
        /// Would blow the total custom-entry memory budget.
        case budgetExceeded
    }

    /// Validates raw user input against the current list and the Arcep ranges, in
    /// precedence order: parse → covered → span budget → duplicate → total budget.
    ///
    /// Coverage is checked before the span budget so that typing `"01 62"` (a full
    /// Arcep range, 10^6 numbers) answers "déjà couvert", not "trop large".
    public static func evaluateAdd(
        raw: String,
        existing: [BlockEntry],
        arcepRanges: [ArcepRange]
    ) -> AddOutcome {
        // Parse with a relaxed span so overbroad-but-covered input is recognized.
        guard let entry = BlockEntry(raw: raw, maxSpanDigits: 8) else { return .invalid }

        if let covering = arcepRanges.first(where: { range in
            guard let run = range.run else { return false }
            return run.contains(entry.run.base) && run.contains(entry.run.upperBound)
        }) {
            return .alreadyCovered(rangeLabel: covering.label)
        }

        if entry.run.count > maxPrefixSpan {
            return .tooBroad
        }

        let subsumed = existing.contains {
            $0.run.contains(entry.run.base) && $0.run.contains(entry.run.upperBound)
        }
        if subsumed {
            return .duplicate
        }

        let spent = existing.reduce(Int64(0)) { $0 + $1.run.count }
        if spent + entry.run.count > customEntryBudget {
            return .budgetExceeded
        }

        return .added(entry)
    }
}
