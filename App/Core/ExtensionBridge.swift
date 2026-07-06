import CallKit
import Foundation

/// The state of the SilenciaBlocker Call Directory extension as iOS reports it.
enum ExtensionStatus: Equatable {
    case unknown
    case enabled
    case disabled
    /// The status query itself failed (typical on the simulator, where the Call
    /// Directory machinery is partly unavailable).
    case unavailable(String)

    var isEnabled: Bool {
        self == .enabled
    }
}

/// Thin async wrapper around `CXCallDirectoryManager` (implementation-plan.md §3.2).
/// Status is re-checked on every foreground transition; reloads are triggered after
/// every config mutation the app persists to the App Group.
struct ExtensionBridge {
    /// Must match the extension target's PRODUCT_BUNDLE_IDENTIFIER in project.yml.
    static let extensionID = "com.silencia.app.blocker"

    func status() async -> ExtensionStatus {
        await withCheckedContinuation { continuation in
            CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(
                withIdentifier: Self.extensionID
            ) { status, error in
                if let error {
                    continuation.resume(returning: .unavailable(error.localizedDescription))
                    return
                }
                switch status {
                case .enabled: continuation.resume(returning: .enabled)
                case .disabled: continuation.resume(returning: .disabled)
                case .unknown: continuation.resume(returning: .unknown)
                @unknown default: continuation.resume(returning: .unknown)
                }
            }
        }
    }

    /// Asks iOS to re-run the extension against the current App Group config.
    /// Returns the error message on failure (best-effort: a failed reload is never
    /// fatal — the next enable/foreground retries deterministically).
    @discardableResult
    func reload() async -> String? {
        await withCheckedContinuation { continuation in
            CXCallDirectoryManager.sharedInstance.reloadExtension(
                withIdentifier: Self.extensionID
            ) { error in
                continuation.resume(returning: error?.localizedDescription)
            }
        }
    }
}
