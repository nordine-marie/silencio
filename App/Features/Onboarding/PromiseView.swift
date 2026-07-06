import SwiftUI

/// Screen 01 — the promise. One sentence, one button.
struct PromiseView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Brand.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 30) {
                    Image("LogoMark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 72)
                        .foregroundStyle(Brand.surface)
                        .frame(width: 132, height: 132)
                        .background(Brand.brick, in: RoundedRectangle(cornerRadius: 36))
                        .shadow(color: Brand.brick.opacity(0.45), radius: 20, y: 12)

                    VStack(spacing: 2) {
                        Text("Bloquez tout le démarchage téléphonique.")
                            .font(.brandDisplay)
                            .foregroundStyle(Brand.ink)
                        Text("À vie.")
                            .font(.brandDisplay)
                            .foregroundStyle(Brand.brick)
                    }
                    .multilineTextAlignment(.center)

                    Text(
                        "Un seul interrupteur, et plus jamais un démarcheur. "
                            + "Sans compte, sans abonnement, et rien ne quitte votre téléphone."
                    )
                    .font(.brandBody)
                    .lineSpacing(4)
                    .foregroundStyle(Brand.inkMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                }

                Spacer()

                VStack(spacing: 14) {
                    Button("Commencer", action: onContinue)
                        .buttonStyle(PrimaryButtonStyle())
                    Text("Achat unique · aucun abonnement")
                        .font(.system(size: 14))
                        .foregroundStyle(Brand.inkFaint)
                }
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    PromiseView(onContinue: {})
}
