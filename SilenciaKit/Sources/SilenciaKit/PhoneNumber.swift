import Foundation

/// French phone-number parsing helpers. The extension needs numbers as ascending
/// `Int64` E.164 values (no `+`); the block-list UI accepts messy human input.
public enum PhoneNumber {
    /// French national significant number length (after the trunk `0`): 9 digits.
    static let nationalDigits = 9
    static let countryCode: Int64 = 33

    /// Normalizes a user-entered French number to its E.164 `Int64` form
    /// (e.g. `"06 12 34 56 78"` → `33612345678`), or `nil` if it isn't a
    /// well-formed French number.
    ///
    /// Accepts common formats: `0612345678`, `06 12 34 56 78`, `06.12.34.56.78`,
    /// `+33612345678`, `0033612345678`, `+33 6 12 34 56 78`.
    public static func normalizeFR(_ raw: String) -> Int64? {
        let digits = raw.unicodeScalars
            .filter { CharacterSet.decimalDigits.contains($0) || $0 == "+" }
            .map(Character.init)
        var national = String(digits)

        if national.hasPrefix("+33") {
            national = String(national.dropFirst(3))
        } else if national.hasPrefix("0033") {
            national = String(national.dropFirst(4))
        } else if national.hasPrefix("33"), national.count == 2 + nationalDigits {
            national = String(national.dropFirst(2))
        } else if national.hasPrefix("0") {
            national = String(national.dropFirst(1))
        } else {
            return nil
        }

        guard national.count == nationalDigits, national.allSatisfy(\.isNumber),
              let nsn = Int64(national)
        else {
            return nil
        }
        // Reject a leading-zero NSN (would collapse a digit); French NSNs start 1–9.
        guard let first = national.first, first != "0" else { return nil }

        return countryCode * Int64(pow10(nationalDigits)) + nsn
    }

    /// Normalizes a custom *prefix* (a partial French number that blocks a whole
    /// span) into a ``BlockingRun``. To bound extension memory, the prefix must
    /// leave at most `maxSpanDigits` trailing digits (default 4 → ≤ 10,000 numbers,
    /// see implementation-plan.md §3.3).
    public static func normalizePrefixFR(_ raw: String, maxSpanDigits: Int = 4) -> BlockingRun? {
        let digits = raw.unicodeScalars
            .filter { CharacterSet.decimalDigits.contains($0) || $0 == "+" }
            .map(Character.init)
        var national = String(digits)

        if national.hasPrefix("+33") {
            national = String(national.dropFirst(3))
        } else if national.hasPrefix("0033") {
            national = String(national.dropFirst(4))
        } else if national.hasPrefix("0") {
            national = String(national.dropFirst(1))
        } else {
            return nil
        }

        guard !national.isEmpty, national.count <= nationalDigits, national.allSatisfy(\.isNumber),
              let first = national.first, first != "0" else { return nil }

        let spanDigits = nationalDigits - national.count
        guard spanDigits >= 0, spanDigits <= maxSpanDigits, let nsnPrefix = Int64(national) else {
            return nil
        }

        let span = Int64(pow10(spanDigits))
        let base = (countryCode * Int64(pow10(nationalDigits))) + (nsnPrefix * span)
        return BlockingRun(base: base, count: span)
    }

    private static func pow10(_ exponent: Int) -> Int {
        (0 ..< exponent).reduce(1) { acc, _ in acc * 10 }
    }
}
