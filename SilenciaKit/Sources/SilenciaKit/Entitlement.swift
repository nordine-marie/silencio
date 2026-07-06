import Foundation

/// The user's purchase tier. Entitlement is resolved in the main app (StoreKit 2);
/// the extension only reads the already-computed active configuration.
public enum Tier: String, Codable, Sendable {
    case free
    case lifetime
}

/// Free-tier vs lifetime gating rules (product-spec.md §6.1 F5, implementation-plan.md §2.6).
public enum Entitlement {
    /// Free tier blocks the two most notorious ranges only, to prove it works.
    public static let freeRangeLabels: Set<String> = ["09 48", "09 49"]

    /// Free tier allows this many custom entries.
    public static let freeCustomLimit = 5

    /// The Arcep ranges active for a given tier: all of them for lifetime, only the
    /// free-sample ranges otherwise.
    public static func activeRanges(from all: [ArcepRange], tier: Tier) -> [ArcepRange] {
        switch tier {
        case .lifetime:
            return all
        case .free:
            return all.filter { freeRangeLabels.contains($0.label) }
        }
    }

    /// How many custom entries the user may add for a given tier.
    public static func customEntryLimit(tier: Tier) -> Int {
        switch tier {
        case .lifetime: return .max
        case .free: return freeCustomLimit
        }
    }
}
