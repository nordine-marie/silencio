import SilenciaKit
import SwiftUI

/// Screens 05/06 — the home screen. "Show, don't configure": a hero status card
/// (brick = protected, amber = paused with a reactivation CTA — never a silent
/// failure), live counts derived from the actual blocking plan, and the privacy
/// covenant. Expected to be opened rarely; it must answer "am I protected?" at
/// a glance.
struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSettings = false
    @State private var showSteps = false

    /// The simulator can't report real extension status; treat everything but an
    /// explicit `.disabled` as protected so the primary state is demonstrable.
    private var isProtected: Bool {
        switch model.extensionStatus {
        case .enabled: return true
        case .disabled: return false
        case .unknown, .unavailable:
            #if targetEnvironment(simulator)
                return true
            #else
                return false
            #endif
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        header

                        if isProtected {
                            activeHero
                        } else {
                            pausedHero
                        }

                        if model.isReloading {
                            reloadBanner
                        }

                        statRow
                            .opacity(isProtected ? 1 : 0.5)

                        updateRow

                        blockListRow

                        PrivacyNote()
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showSteps) {
                stepsSheet
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "blocklist" {
                    BlockListView()
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task { await model.refreshExtensionStatus() }
            }
        }
    }

    // MARK: Pieces

    private var header: some View {
        HStack {
            Text("Silencia")
                .font(.brandHeader)
                .foregroundStyle(Brand.ink)
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Brand.inkFaint)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Réglages")
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private var activeHero: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(Brand.cream)
                .frame(width: 86, height: 86)
                .background(Brand.cream.opacity(0.16), in: RoundedRectangle(cornerRadius: 26))
            Text("Protection active")
                .font(.brandTitle)
                .foregroundStyle(Brand.cream)
            Text("Le mur est dressé. Tout le démarchage est bloqué.")
                .font(.brandSecondary)
                .lineSpacing(3)
                .foregroundStyle(Brand.brickSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 28)
        .background(Brand.brick, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: Brand.brick.opacity(0.4), radius: 18, y: 10)
    }

    private var pausedHero: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.shield")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(Brand.cream)
                .frame(width: 86, height: 86)
                .background(Brand.amber, in: RoundedRectangle(cornerRadius: 26))
            Text("Protection en pause")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Brand.ink)
            Text(
                "Silencia a été désactivé dans les Réglages iOS. "
                    + "Réactivez-le pour retrouver le silence — ça prend 15 secondes."
            )
            .font(.brandSecondary)
            .lineSpacing(3)
            .foregroundStyle(Brand.inkMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 280)
            Button("Réactiver la protection") {
                showSteps = true
            }
            .buttonStyle(PrimaryButtonStyle(background: Brand.amber))
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(Brand.amberBg, in: RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Brand.amberBorder, lineWidth: 1)
        )
    }

    private var stepsSheet: some View {
        ReactivationSheet()
            .presentationDetents([.medium, .large])
    }

    private var reloadBanner: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(Brand.brick)
            Text("Chargement des \(FrenchFormat.count(model.activePlan.totalEntries)) de numéros…")
                .font(.system(size: 14))
                .foregroundStyle(Brand.inkMuted)
            Spacer(minLength: 0)
        }
        .padding(16)
        .card(cornerRadius: 16)
    }

    private var statRow: some View {
        HStack(spacing: 14) {
            StatCard(
                value: FrenchFormat.compactCount(model.activePlan.totalEntries),
                label: "numéros couverts"
            )
            StatCard(
                value: "\(model.rangeData.ranges.count)",
                label: "plages officielles"
            )
        }
    }

    private var updateRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Brand.plum)
            VStack(alignment: .leading, spacing: 2) {
                Text("Liste à jour")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Brand.ink)
                Text("Dernière mise à jour · \(FrenchFormat.date(fromISO: model.rangeData.updated))")
                    .font(.brandCaption)
                    .foregroundStyle(Brand.inkFaint)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var blockListRow: some View {
        NavigationLink(value: "blocklist") {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Brand.brick)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mes numéros bloqués")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Brand.ink)
                    Text(blockListSubtitle)
                        .font(.brandCaption)
                        .foregroundStyle(Brand.inkFaint)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Brand.inkFaint)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
    }

    private var blockListSubtitle: String {
        switch model.userEntries.count {
        case 0: "Ajouter un numéro ou un préfixe"
        case 1: "1 ajout personnel"
        default: "\(model.userEntries.count) ajouts personnels"
        }
    }
}

/// The paused-state helper sheet: reuses the onboarding steps and the Settings link.
struct ReactivationSheet: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Brand.cream.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("Réactiver Silencia")
                    .font(.brandScreenTitle)
                    .foregroundStyle(Brand.ink)
                Text("Vos réglages et votre achat sont conservés. Rien n'est perdu.")
                    .font(.brandRow)
                    .foregroundStyle(Brand.inkMuted)
                    .padding(.top, 8)

                ActivationStepsCard()
                    .padding(.top, 20)

                Spacer()

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                        dismiss()
                    }
                } label: {
                    Label("Ouvrir les Réglages", systemImage: "gear")
                }
                .buttonStyle(PrimaryButtonStyle(background: Brand.amber))
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppModel())
}
