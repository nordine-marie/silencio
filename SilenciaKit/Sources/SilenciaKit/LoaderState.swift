import Foundation

/// The cursor of the paged Call Directory load, persisted in the App Group
/// (paged-loading-plan.md §2.2). Ownership is the mirror of `SharedConfig`:
/// **the extension writes it** after each emitted page; the app only reads it
/// (progress, completion checks) or deletes it (force a full rebuild).
public struct LoaderState: Codable, Equatable, Sendable {
    /// Bumped when the on-disk shape changes; `load()` treats older files as
    /// absent, which the decision function resolves as a deterministic rebuild.
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    /// `BlockingPlan.fingerprint` of the plan this cursor was computed against.
    public var planFingerprint: UInt64
    /// Entries emitted so far — an index into the plan's canonical ascending stream.
    public var entriesLoaded: Int64
    public var totalEntries: Int64

    public init(planFingerprint: UInt64, entriesLoaded: Int64, totalEntries: Int64) {
        schemaVersion = Self.currentSchemaVersion
        self.planFingerprint = planFingerprint
        self.entriesLoaded = entriesLoaded
        self.totalEntries = totalEntries
    }

    public var isComplete: Bool {
        entriesLoaded >= totalEntries
    }

    /// Fraction loaded in 0…1 (an empty plan is trivially complete).
    public var progress: Double {
        guard totalEntries > 0 else { return 1 }
        return min(1, Double(entriesLoaded) / Double(totalEntries))
    }
}

// MARK: - App Group persistence

public extension LoaderState {
    static let fileName = "loader-state.json"

    /// URL of the state file inside the shared App Group container, or `nil` if the
    /// container is unavailable (e.g. running in a plain unit-test process).
    static func fileURL(appGroupID: String = SharedConfig.appGroupID) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    /// Loads the persisted cursor, or `nil` if absent, unreadable, or written by an
    /// incompatible schema — all of which `PagedLoader.nextAction` resolves as a
    /// deterministic full rebuild.
    static func load(appGroupID: String = SharedConfig.appGroupID) -> LoaderState? {
        guard let url = fileURL(appGroupID: appGroupID),
              let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(LoaderState.self, from: data),
              state.schemaVersion == currentSchemaVersion else { return nil }
        return state
    }

    /// Persists the cursor (extension-side only, just before `completeRequest()` —
    /// see paged-loading-plan.md §2.8 for why optimistic save is the right trade).
    func save(appGroupID: String = SharedConfig.appGroupID) throws {
        guard let url = Self.fileURL(appGroupID: appGroupID) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try JSONEncoder().encode(self)
        try data.write(to: url, options: .atomic)
    }

    /// Deletes the cursor so the next request rebuilds from scratch. Used by the
    /// extension on `requestFailed` and by the app's recovery paths (reload error,
    /// « Recharger la liste » maintenance action).
    static func invalidate(appGroupID: String = SharedConfig.appGroupID) {
        guard let url = fileURL(appGroupID: appGroupID) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
