import Foundation

/// The versioned Arcep range dataset.
///
/// Bundled with the app and refreshable from a signed static JSON file on a CDN
/// (see implementation-plan.md §3.4). The extension only ever reads validated data.
public struct RangeData: Codable, Equatable, Sendable {
    public let version: Int
    /// ISO date string (`YYYY-MM-DD`) of the last Arcep update this data reflects.
    public let updated: String
    public let ranges: [ArcepRange]

    public init(version: Int, updated: String, ranges: [ArcepRange]) {
        self.version = version
        self.updated = updated
        self.ranges = ranges
    }
}

// MARK: - Validation

public extension RangeData {
    enum ValidationError: Error, Equatable, CustomStringConvertible {
        case emptyRanges
        case malformedPrefix(String)
        case overlappingRanges(String, String)

        public var description: String {
            switch self {
            case .emptyRanges:
                return "range data contains no ranges"
            case .malformedPrefix(let p):
                return "malformed prefix '\(p)' (expected \(ArcepRange.prefixLength) digits)"
            case .overlappingRanges(let a, let b):
                return "ranges '\(a)' and '\(b)' overlap; Arcep ranges must be disjoint"
            }
        }
    }

    /// Validates the invariants the extension relies on: every prefix is well-formed
    /// and the resulting blocking runs are pairwise disjoint. Disjointness is enforced
    /// here (in the app), never in the memory-constrained extension.
    func validate() throws {
        guard !ranges.isEmpty else { throw ValidationError.emptyRanges }

        var runs: [(range: ArcepRange, run: BlockingRun)] = []
        for range in ranges {
            guard let run = range.run else {
                throw ValidationError.malformedPrefix(range.prefix)
            }
            runs.append((range, run))
        }

        let sorted = runs.sorted { $0.run.base < $1.run.base }
        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            if curr.run.base <= prev.run.upperBound {
                throw ValidationError.overlappingRanges(prev.range.prefix, curr.range.prefix)
            }
        }
    }

    /// Total number of subscriber numbers covered (e.g. 12,000,000 for the 12 ranges).
    var totalNumbersCovered: Int64 {
        ranges.reduce(0) { $0 + $1.count }
    }
}

// MARK: - Bundled default

public extension RangeData {
    /// The 12 Arcep telemarketing prefixes, hardcoded as the ship-safe fallback.
    /// The app never *requires* network: bundled ranges always work.
    static let bundledDefault = RangeData(
        version: 1,
        updated: "2026-07-01",
        ranges: [
            ArcepRange(prefix: "33162", label: "01 62"),
            ArcepRange(prefix: "33163", label: "01 63"),
            ArcepRange(prefix: "33270", label: "02 70"),
            ArcepRange(prefix: "33271", label: "02 71"),
            ArcepRange(prefix: "33377", label: "03 77"),
            ArcepRange(prefix: "33378", label: "03 78"),
            ArcepRange(prefix: "33424", label: "04 24"),
            ArcepRange(prefix: "33425", label: "04 25"),
            ArcepRange(prefix: "33568", label: "05 68"),
            ArcepRange(prefix: "33569", label: "05 69"),
            ArcepRange(prefix: "33948", label: "09 48"),
            ArcepRange(prefix: "33949", label: "09 49"),
        ]
    )

    /// Loads and validates `ranges.json` bundled in the package resources.
    /// Falls back to ``bundledDefault`` if the resource is missing or invalid.
    static func loadBundled() -> RangeData {
        loadBundled(from: .module)
    }

    /// Loads and validates `ranges.json` from an explicit bundle (e.g. the app or
    /// extension bundle, which each ship their own copy of the resource).
    static func loadBundled(from bundle: Bundle) -> RangeData {
        guard let url = bundle.url(forResource: "ranges", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(RangeData.self, from: data),
              (try? decoded.validate()) != nil
        else { return bundledDefault }
        return decoded
    }
}
