import SilenciaKit
import SwiftUI

/// Screen 03 — Activation, THE screen. The only hard step is Apple's fault; this
/// screen owns it: illustrated steps, a Settings deep link, and live detection of
/// the extension being enabled (poll on a short cadence while visible — the app
/// "celebrates the moment the user returns", product-spec.md F2).
struct ActivationView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openURL) private var openURL
    let onActivated: () -> Void
    let onLater: () -> Void

    var body: some View {
        ZStack {
            Brand.cream.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("Dernière étape")
                    .font(.brandScreenTitle)
                    .foregroundStyle(Brand.ink)

                Text(
                    "iOS demande d'activer Silencia une seule fois dans les Réglages. "
                        + "Suivez les 5 étapes — on détecte automatiquement quand c'est fait."
                )
                .font(.brandRow)
                .lineSpacing(3)
                .foregroundStyle(Brand.inkMuted)
                .padding(.top, 10)

                ActivationStepsCard()
                    .padding(.top, 22)

                Spacer()

                // This screen's only job is to wait for the toggle. The moment the
                // extension is enabled we advance to Success, which owns the paged
                // load's progress UI — so there's no "loading numbers" state here.
                waitingIndicator

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Ouvrir les Réglages", systemImage: "gear")
                }
                .buttonStyle(PrimaryButtonStyle())

                bottomLinks
            }
            .padding(.horizontal, 34)
            .padding(.top, 26)
            .padding(.bottom, 16)
        }
        .task { await pollForActivation() }
    }

    private var waitingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: 0xC6A98F))
                .frame(width: 9, height: 9)
            Text("En attente de l'activation…")
                .font(.system(size: 14))
                .foregroundStyle(Brand.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 14)
    }

    private var bottomLinks: some View {
        HStack {
            Button("Plus tard", action: onLater)
                .font(.brandSecondary)
                .foregroundStyle(Brand.inkFaint)
            #if targetEnvironment(simulator)
                Spacer()
                Button("Simulateur : continuer") {
                    model.simulateActivation()
                }
                .font(.brandSecondary)
                .foregroundStyle(Brand.plum)
            #endif
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
    }

    /// Polls the extension status while the screen is visible (`.task` cancels on
    /// disappear). On detection: start the paged load, then the success state.
    private func pollForActivation() async {
        while !Task.isCancelled {
            // A paged load already in flight means iOS enabled the extension and
            // `syncExtension` is underway (e.g. `start()` detected an already-enabled
            // extension before this screen appeared). We're past activation — advance
            // regardless of what a transiently-flapping status query reports.
            if model.isReloading {
                onActivated()
                return
            }

            await model.refreshExtensionStatus()

            #if targetEnvironment(simulator)
                // The simulator can't report real status; drop `.unavailable` so we
                // keep waiting for the dev shortcut (simulateActivation) instead of
                // spinning on a failing query.
                if case .unavailable = model.extensionStatus {
                    model.clearUnavailableStatus()
                }
            #endif

            if model.extensionStatus.isEnabled {
                // Kick the paged load off without blocking the success moment: the
                // unstructured task survives this screen's dismissal, holds a
                // background assertion, and BGProcessingTask + foreground resume
                // finish whatever is left.
                Task { await model.syncExtension() }
                onActivated()
                return
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }
}

/// The 5 illustrated steps (Settings → Apps → Phone → Call Blocking → toggle).
/// Reused by the dashboard's paused state.
struct ActivationStepsCard: View {
    var body: some View {
        VStack(spacing: 0) {
            step(1, color: Brand.plum) {
                Text("Ouvrir ") + Text("Réglages").fontWeight(.bold)
            }
            divider
            step(2, color: Brand.plum) {
                Text("Aller dans ") + Text("Apps").fontWeight(.bold)
            }
            divider
            step(3, color: Brand.plum) {
                Text("Toucher ") + Text("Téléphone").fontWeight(.bold)
            }
            divider
            step(4, color: Brand.plum) {
                Text("Blocage & identification d'appel")
            }
            divider
            step(5, color: Brand.brick) {
                Text("Activer ") + Text("Silencia").fontWeight(.bold)
            } trailing: {
                toggleGlyph
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .card(cornerRadius: 22)
    }

    private var divider: some View {
        Rectangle().fill(Brand.divider).frame(height: 1)
    }

    private var toggleGlyph: some View {
        Capsule()
            .fill(Brand.green)
            .frame(width: 38, height: 23)
            .overlay(alignment: .trailing) {
                Circle().fill(.white).frame(width: 19, height: 19).padding(2)
            }
    }

    private func step(
        _ number: Int,
        color: Color,
        @ViewBuilder label: () -> Text,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) -> some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(color, in: Circle())
            label()
                .font(.system(size: 15.5))
                .foregroundStyle(Brand.ink)
            trailing()
            Spacer(minLength: 0)
        }
        .padding(.vertical, 13)
    }
}

#Preview {
    ActivationView(onActivated: {}, onLater: {})
        .environmentObject(AppModel())
}
