import Foundation

/// A single Arcep telemarketing number range.
///
/// In France, commercial prospecting platforms are legally required to call from
/// known number ranges (Arcep decision, effective 2023-01-01). Each range is a
/// 5-digit E.164 prefix (country code + national prefix) covering exactly
/// 1,000,000 consecutive subscriber numbers.
///
/// Example: prefix `"33162"` (i.e. `+33 1 62 ..`) covers `33162000000...33162999999`.
public struct ArcepRange: Codable, Equatable, Hashable, Sendable {
    /// E.164 prefix without the leading `+`, e.g. `"33162"`. Always 5 digits for
    /// the current Arcep ranges (country code `33` + 3-digit national block).
    public let prefix: String

    /// Human-facing French label, e.g. `"01 62"`.
    public let label: String

    public init(prefix: String, label: String) {
        self.prefix = prefix
        self.label = label
    }

    /// Number of subscriber numbers covered by this range (10^6 for a 5-digit prefix).
    public var count: Int64 {
        Self.spanCount
    }

    /// The lowest E.164 number in the range as an `Int64`, e.g. `33162000000`.
    ///
    /// Returns `nil` if the prefix is not a valid 5-digit numeric string.
    public var base: Int64? {
        guard prefix.count == Self.prefixLength,
              prefix.allSatisfy(\.isNumber),
              let value = Int64(prefix)
        else { return nil }
        return value * Self.spanCount
    }

    /// The contiguous blocking run this range expands to, or `nil` if invalid.
    public var run: BlockingRun? {
        guard let base else { return nil }
        return BlockingRun(base: base, count: count)
    }

    static let prefixLength = 5
    static let spanCount: Int64 = 1_000_000
}
