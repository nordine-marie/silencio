import SwiftUI

/// Routes between the first-launch onboarding flow and the steady-state dashboard.
struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        content
            .task { await model.start() }
            .tint(Brand.brick)
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG
            if let screen = DebugScreen.fromLaunchArguments() {
                DebugScreenView(screen: screen)
            } else {
                flow
            }
        #else
            flow
        #endif
    }

    @ViewBuilder
    private var flow: some View {
        if model.onboardingComplete {
            DashboardView()
        } else {
            OnboardingFlow()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppModel())
}
