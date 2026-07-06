import Foundation

/// The single source of truth shared between the app and the extension via the
/// App Group container. The app owns writes (range data, user entries); the
/// extension only reads it (implementation-plan.md §3.3).
///
/// Silencia is paid upfront (business-plan.md): there is no tier or entitlement —
/// every install blocks every range.
///
/// `plan()` is pure and unit-tested; the file IO is a thin, failure-tolerant layer.
public struct SharedConfig: Codable, Equatable, Sendable {
    public var rangeData: RangeData
    /// Custom numbers/prefixes the user added (F3), with display metadata.
    public var userEntries: [BlockEntry]

    public init(rangeData: RangeData, userEntries: [BlockEntry] = []) {
        self.rangeData = rangeData
        self.userEntries = userEntries
    }

    /// The user's entries as bare runs — what the plan merges into the stream.
    public var userRuns: [BlockingRun] {
        userEntries.map(\.run)
    }

    /// The blocking plan implied by this config: all Arcep ranges merged with the
    /// user's entries.
    public func plan() -> BlockingPlan {
        BlockingPlan(arcepRanges: rangeData.ranges, userRuns: userRuns)
    }
}

// MARK: - App Group persistence

public extension SharedConfig {
    static let appGroupID = "group.com.silencia.shared"
    static let fileName = "config.json"

    /// URL of the config file inside the shared App Group container, or `nil` if the
    /// container is unavailable (e.g. running in a plain unit-test process).
    static func fileURL(appGroupID: String = appGroupID) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    /// Loads the persisted config, or `nil` if absent/unreadable. Callers fall back
    /// to bundled defaults — the app must never *require* the file to exist.
    static func load(appGroupID: String = appGroupID) -> SharedConfig? {
        guard let url = fileURL(appGroupID: appGroupID),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SharedConfig.self, from: data)
    }

    /// Persists the config to the App Group container (app-side only).
    func save(appGroupID: String = appGroupID) throws {
        guard let url = Self.fileURL(appGroupID: appGroupID) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try JSONEncoder().encode(self)
        try data.write(to: url, options: .atomic)
    }
}
