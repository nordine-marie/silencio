import SwiftUI

/// First-launch flow (product-spec.md §7.1, target < 90 s to protected):
/// Promise → How it works (skippable) → Activation (THE screen) → Success.
struct OnboardingFlow: View {
    @EnvironmentObject private var model: AppModel
    @State private var stage: Stage = .promise

    enum Stage {
        case promise, howItWorks, activation, success
    }

    var body: some View {
        ZStack {
            switch stage {
            case .promise:
                PromiseView(onContinue: { stage = .howItWorks })
                    .transition(.opacity)
            case .howItWorks:
                HowItWorksView(onContinue: { stage = .activation })
                    .transition(.opacity)
            case .activation:
                ActivationView(
                    onActivated: { stage = .success },
                    onLater: { model.onboardingComplete = true }
                )
                .transition(.opacity)
            case .success:
                SuccessView(onDone: { model.onboardingComplete = true })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: stage)
    }
}
