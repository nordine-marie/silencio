import Foundation

/// A user-added block-list entry: a single number or a bounded prefix (F3).
///
/// Stores the normalized national digits (after the trunk `0`) plus the expanded
/// ``BlockingRun`` so the UI can render a French-formatted label and the extension
/// can merge the run into the ascending stream without re-parsing anything.
public struct BlockEntry: Codable, Equatable, Hashable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        /// A complete French number (run of exactly 1).
        case number
        /// A partial number blocking a whole span (run of 10^k, k ≤ 4 — see
        /// implementation-plan.md §3.3 for the memory-budget rationale).
        case prefix
    }

    /// National digits after the trunk `0`, e.g. `"612345678"` or `"948"`.
    public let nationalDigits: String
    public let kind: Kind
    public let run: BlockingRun

    public var id: String {
        "\(kind.rawValue):\(nationalDigits)"
    }

    /// Parses messy user input into an entry. 9 national digits (or full E.164)
    /// make a `.number`; anything shorter a `.prefix` spanning up to
    /// `maxSpanDigits` trailing digits. The default (4 → ≤ 10,000 numbers) is the
    /// storage budget; ``BlockListLogic`` parses more broadly so that overbroad
    /// input can still be recognized as "déjà couvert" before being rejected.
    public init?(raw: String, maxSpanDigits: Int = 4) {
        if let value = PhoneNumber.normalizeFR(raw) {
            kind = .number
            run = BlockingRun(base: value, count: 1)
            nationalDigits = String(value % 1_000_000_000 + 1_000_000_000).dropFirst().description
        } else if let run = PhoneNumber.normalizePrefixFR(raw, maxSpanDigits: maxSpanDigits) {
            kind = .prefix
            self.run = run
            let spanDigits = Int(log10(Double(run.count)).rounded())
            // run.base = "33" + 9 national digits; drop "33" and the span's trailing zeros.
            nationalDigits = String(String(run.base).dropFirst(2).dropLast(spanDigits))
        } else {
            return nil
        }
    }

    /// French-formatted display string: `"06 12 34 56 78"` for numbers,
    /// `"09 48"` (pair-grouped, possibly with a trailing odd digit) for prefixes.
    public var display: String {
        let withTrunk = "0" + nationalDigits
        var groups: [String] = []
        var index = withTrunk.startIndex
        while index < withTrunk.endIndex {
            let next = withTrunk.index(index, offsetBy: 2, limitedBy: withTrunk.endIndex) ?? withTrunk
                .endIndex
            groups.append(String(withTrunk[index ..< next]))
            index = next
        }
        return groups.joined(separator: " ")
    }
}
