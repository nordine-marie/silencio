#if DEBUG
    import SilenciaKit
    import SwiftUI

    /// Harness-only deep links: `scripts/run.sh` can't tap the UI, so each screen
    /// is reachable directly via a launch argument for visual verification:
    ///
    ///     xcrun simctl launch booted com.silencia.app --screen=dashboard
    ///
    /// Debug builds only; release builds compile none of this.
    enum DebugScreen: String, CaseIterable {
        case promise, how, activation, success
        case dashboard, paused, blocklist, settings

        static func fromLaunchArguments() -> DebugScreen? {
            for argument in CommandLine.arguments where argument.hasPrefix("--screen=") {
                return DebugScreen(rawValue: String(argument.dropFirst("--screen=".count)))
            }
            return nil
        }
    }

    struct DebugScreenView: View {
        let screen: DebugScreen

        var body: some View {
            switch screen {
            case .promise:
                PromiseView(onContinue: {})
            case .how:
                HowItWorksView(onContinue: {})
            case .activation:
                ActivationView(onActivated: {}, onLater: {})
            case .success:
                SuccessView(onDone: {})
            case .dashboard, .paused:
                DashboardView()
            case .blocklist:
                NavigationStack {
                    BlockListView()
                }
            case .settings:
                SettingsView()
            }
        }
    }
#endif
