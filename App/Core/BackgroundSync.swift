import BackgroundTasks
import Foundation

/// Background continuation of the paged Call Directory load — the first full load
/// is ~7 reload rounds and must not require the user to keep the app open.
///
/// Three complementary layers (paged-loading-plan.md §2.7):
/// 1. `AppModel.syncExtension` holds a background-task assertion, so a load in
///    flight keeps running for the grace period when the user leaves the app.
/// 2. This `BGProcessingTask` re-launches the loop later if the load is still
///    incomplete (iOS picks the moment — typically device idle).
/// 3. `AppModel.onForeground()` resumes on the next app open — the safety net
///    that needs no scheduling at all.
@MainActor
enum BackgroundSync {
    /// Must stay in sync with BGTaskSchedulerPermittedIdentifiers (project.yml).
    static let taskID = "com.silencia.app.sync"

    /// Registers the launch handler. Must run before the app finishes launching
    /// (called from `SilenciaApp.init`).
    static func register(model: AppModel) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: .main) { task in
            MainActor.assumeIsolated {
                handle(task, model: model)
            }
        }
    }

    /// Schedules a continuation when the app leaves the foreground with an
    /// unfinished load. Submit errors are non-fatal (e.g. simulator, Low Power
    /// Mode): the foreground resume covers those paths.
    static func scheduleIfNeeded(model: AppModel) {
        guard model.extensionStatus.isEnabled, model.needsSync else { return }
        let request = BGProcessingTaskRequest(identifier: taskID)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            NSLog("[Silencia] background sync scheduling failed: \(error.localizedDescription)")
        }
    }

    private static func handle(_ task: BGTask, model: AppModel) {
        let sync = Task { @MainActor in
            await model.syncExtension()
            // Interrupted again (expiration, a failed round)? Queue another pass;
            // completion is judged by the persisted cursor, not the loop's exit.
            scheduleIfNeeded(model: model)
            task.setTaskCompleted(success: !model.needsSync)
        }
        task.expirationHandler = {
            sync.cancel()
        }
    }
}
