import SwiftUI

@main
struct SilenciaApp: App {
    @StateObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let model = AppModel()
        _model = StateObject(wrappedValue: model)
        // BGTaskScheduler requires registration before launch completes.
        BackgroundSync.register(model: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                // Leaving with an unfinished paged load: let iOS finish it for us.
                BackgroundSync.scheduleIfNeeded(model: model)
            }
        }
    }
}
