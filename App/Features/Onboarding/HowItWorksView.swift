import SilenciaKit
import SwiftUI

/// Screen 02 — the Arcep explanation in two sentences. Builds trust in the
/// deterministic claim; skippable, never required reading.
struct HowItWorksView: View {
    @EnvironmentObject private var model: AppModel
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Brand.cream.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Button("Passer", action: onContinue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Brand.inkFaint)
                }
                .padding(.bottom, 24)

                Text("Pourquoi ça marche à tous les coups")
                    .font(.brandScreenTitle)
                    .foregroundStyle(Brand.ink)

                explainer
                    .font(.brandBody)
                    .lineSpacing(4)
                    .foregroundStyle(Brand.inkMuted)
                    .padding(.top, 14)

                VStack(spacing: 16) {
                    InfoCard(
                        icon: "rectangle.grid.1x2",
                        iconColor: Brand.brick,
                        title: "\(model.rangeData.ranges.count) plages officielles",
                        subtitle: "~\(coveredCount) de numéros couverts"
                    )
                    InfoCard(
                        icon: "lock",
                        iconColor: Brand.plum,
                        title: "100 % sur votre téléphone",
                        subtitle: "Rien n'est envoyé, rien n'est stocké"
                    )
                }
                .padding(.top, 34)

                Spacer()

                Button("J'ai compris", action: onContinue)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 34)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    private var coveredCount: String {
        FrenchFormat.count(model.rangeData.totalNumbersCovered)
    }

    private var explainer: Text {
        Text("Depuis 2023, la loi française (Arcep) oblige les démarcheurs à appeler depuis ")
            + Text("\(model.rangeData.ranges.count) plages de numéros connues")
            .fontWeight(.bold)
            .foregroundColor(Brand.ink)
            + Text(". Silencia les bloque toutes — ce n'est pas une supposition, c'est déterministe.")
    }
}

#Preview {
    HowItWorksView(onContinue: {})
        .environmentObject(AppModel())
}
