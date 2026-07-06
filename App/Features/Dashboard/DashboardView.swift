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
                            // While the paged load runs, the hero tells the truth:
                            // the wall is going up, not up yet.
                            if case let .loading(loaded, total) = model.loadProgress {
                                loadingHero(loaded: loaded, total: total)
                            } else {
                                activeHero
                            }
                        } else {
                            pausedHero
                        }

                        if case .failed = model.loadProgress {
                            failedBanner
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
                // Re-check status AND resume an unfinished paged load (self-healing).
                Task { await model.onForeground() }
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

    /// The activation-in-progress hero: same brick surface as the active state
    /// (protection is arriving, not paused), a shield without its checkmark yet,
    /// and the brick-course progress bar — one brick per Arcep range. The stream
    /// loads in ascending order and each range spans one million numbers, so a
    /// full brick means that range is genuinely blocked already.
    private func loadingHero(loaded: Int64, total: Int64) -> some View {
        let progress = total > 0 ? Double(loaded) / Double(total) : 0
        let rangeCount = max(1, model.rangeData.ranges.count)
        let blockedRanges = min(rangeCount, Int(progress * Double(rangeCount)))

        return VStack(spacing: 16) {
            Image(systemName: "shield")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(Brand.cream)
                .frame(width: 86, height: 86)
                .background(Brand.cream.opacity(0.16), in: RoundedRectangle(cornerRadius: 26))
            Text("Activation en cours")
                .font(.brandTitle)
                .foregroundStyle(Brand.cream)
            Text(loadingSubtitle(blockedRanges: blockedRanges, rangeCount: rangeCount))
                .font(.brandSecondary)
                .lineSpacing(3)
                .foregroundStyle(Brand.brickSoft)
                .multilineTextAlignment(.center)
            BrickProgressBar(progress: progress, segments: rangeCount)
                .padding(.top, 8)
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 28)
        .background(Brand.brick, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: Brand.brick.opacity(0.4), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(Int(progress * 100)) pour cent")
    }

    private func loadingSubtitle(blockedRanges: Int, rangeCount: Int) -> String {
        guard blockedRanges > 0 else {
            return "Le mur se dresse — première plage en cours de blocage."
        }
        let s = blockedRanges > 1 ? "s" : ""
        return "Le mur se dresse — \(blockedRanges) plage\(s) sur \(rangeCount) déjà bloquée\(s)."
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

    private var failedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Brand.amber)
            Text("Le chargement des numéros n'a pas abouti.")
                .font(.system(size: 14))
                .foregroundStyle(Brand.inkMuted)
            Spacer(minLength: 0)
            Button("Réessayer") {
                Task { await model.retrySync() }
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Brand.brick)
        }
        .padding(16)
        .card(cornerRadius: 16)
    }

    private var statRow: some View {
        HStack(spacing: 14) {
            StatCard(
                value: FrenchFormat.approxMillions(model.activePlan.totalEntries),
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

/// The signature of the loading state: a course of bricks, one per Arcep range,
/// filling left to right as the ascending stream loads. The structure encodes the
/// data — a full brick ⟺ that range is genuinely blocked already.
struct BrickProgressBar: View {
    /// Overall fraction loaded, 0…1.
    let progress: Double
    /// One brick per range (12 for the bundled Arcep set).
    let segments: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0 ..< segments, id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3.5)
                            .fill(Brand.cream.opacity(0.18))
                        RoundedRectangle(cornerRadius: 3.5)
                            .fill(Brand.cream)
                            .frame(width: geo.size.width * fill(of: index))
                    }
                }
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true) // the hero combines and voices the percentage
    }

    /// How full brick `index` is: the bar fills strictly left to right, mirroring
    /// the ascending number stream.
    private func fill(of index: Int) -> Double {
        min(1, max(0, progress * Double(segments) - Double(index)))
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
