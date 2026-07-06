import SwiftUI
import SilenciaKit

/// Demo dashboard. It is intentionally thin — its job in the harness is to prove
/// the app launches, links `SilenciaKit`, and renders real data derived from the
/// same logic the extension uses. The production Onboarding/Dashboard features
/// (see implementation-plan.md §3) replace this.
struct RootView: View {
    private let rangeData = RangeData.loadBundled()

    /// The full lifetime-tier plan — 12,000,000 numbers across 12 ranges.
    private var plan: BlockingPlan {
        BlockingPlan(arcepRanges: rangeData.ranges)
    }

    private var formattedTotal: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.locale = Locale(identifier: "fr_FR")
        return fmt.string(from: NSNumber(value: plan.totalEntries)) ?? "\(plan.totalEntries)"
    }

    var body: some View {
        ZStack {
            Brand.cream.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(Brand.brick)

                VStack(spacing: 8) {
                    Text("Protection active")
                        .font(.title.bold())
                        .foregroundStyle(Brand.ink)
                    Text("\(formattedTotal) numéros bloqués")
                        .font(.headline)
                        .foregroundStyle(Brand.brick)
                }

                VStack(spacing: 12) {
                    stat("Plages Arcep couvertes", "\(rangeData.ranges.count)")
                    stat("Dernière mise à jour", rangeData.updated)
                    stat("Entrées de blocage", formattedTotal)
                }
                .padding(20)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                Text("Vous n'entendrez plus jamais un démarcheur.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
                Text("Silencia · harness demo")
                    .font(.caption)
                    .foregroundStyle(Brand.ink.opacity(0.4))
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Brand.ink.opacity(0.7))
            Spacer()
            Text(value).font(.body.weight(.semibold)).foregroundStyle(Brand.ink)
        }
    }
}

#Preview {
    RootView()
}
