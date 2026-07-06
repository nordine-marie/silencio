import SilenciaKit
import SwiftUI

/// Screen 04 — success. Full brick takeover: the wall is up.
/// The count is the *real* active plan (12 millions lifetime, 2 millions free).
struct SuccessView: View {
    @EnvironmentObject private var model: AppModel
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Brand.brick.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 30) {
                    ZStack {
                        Circle()
                            .fill(Brand.cream.opacity(0.14))
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(Brand.cream)
                            .frame(width: 88, height: 88)
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Brand.brick)
                    }

                    VStack(spacing: 12) {
                        Text(FrenchFormat.count(model.activePlan.totalEntries))
                            .font(.system(size: 44, weight: .heavy))
                            .foregroundStyle(Brand.cream)
                        Text("de numéros bloqués.")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Brand.brickTint)
                    }

                    Text(
                        "Vous n'entendrez plus jamais un démarcheur. "
                            + "Vous pouvez oublier Silencia — il veille."
                    )
                    .font(.system(size: 18))
                    .lineSpacing(4)
                    .foregroundStyle(Brand.brickSoft)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                }

                Spacer()

                Button("Terminé", action: onDone)
                    .buttonStyle(PrimaryButtonStyle(background: Brand.cream, foreground: Brand.brick))
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    SuccessView(onDone: {})
        .environmentObject(AppModel())
}
