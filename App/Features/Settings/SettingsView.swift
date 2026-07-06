import SilenciaKit
import SwiftUI

/// Settings sheet: FAQ (incl. « pourquoi ça marche » and the collateral-blocking
/// note), privacy policy, support. Deliberately short — the product succeeds when
/// the user forgets it exists. Paid upfront: nothing to buy or restore in-app.
struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Réglages")
                                .font(.brandHeader)
                                .foregroundStyle(Brand.ink)
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Brand.inkFaint)
                                    .frame(width: 44, height: 44, alignment: .trailing)
                            }
                            .accessibilityLabel("Fermer")
                        }
                        .padding(.bottom, 12)

                        section("Aide") {
                            navRow(
                                icon: "questionmark.circle",
                                tint: Brand.plum,
                                title: "Questions fréquentes"
                            ) {
                                FAQView()
                            }
                            divider
                            navRow(icon: "hand.raised", tint: Brand.plum, title: "Confidentialité") {
                                PrivacyPolicyView()
                            }
                            divider
                            row(
                                icon: "envelope",
                                tint: Brand.plum,
                                title: "Nous écrire",
                                subtitle: "support@silencia.app"
                            ) {
                                if let url = URL(string: "mailto:support@silencia.app") {
                                    openURL(url)
                                }
                            }
                        }

                        Text("Silencia \(appVersion) · Fait en France · Aucune donnée collectée")
                            .font(.brandCaption)
                            .foregroundStyle(Brand.inkFaint)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 28)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Pieces

    private var divider: some View {
        Rectangle().fill(Brand.divider).frame(height: 1)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.brandCaption)
                .foregroundStyle(Brand.inkFaint)
                .textCase(.uppercase)
                .kerning(0.5)
                .padding(.horizontal, 4)
            VStack(spacing: 0, content: content)
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
                .card()
        }
        .padding(.top, 22)
    }

    private func row(
        icon: String, tint: Color, title: String, subtitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(Brand.chip, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundStyle(Brand.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.brandCaption)
                            .foregroundStyle(Brand.inkFaint)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Brand.inkFaint)
            }
            .padding(.vertical, 12)
        }
    }

    private func navRow(
        icon: String, tint: Color, title: String,
        @ViewBuilder destination: () -> some View
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(Brand.chip, in: RoundedRectangle(cornerRadius: 12))
                Text(title)
                    .font(.system(size: 15.5, weight: .bold))
                    .foregroundStyle(Brand.ink)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Brand.inkFaint)
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - FAQ

struct FAQView: View {
    private struct Item: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    // Long-form French prose reads better unwrapped.
    // swiftlint:disable line_length
    private let items = [
        Item(
            question: "Pourquoi ça marche à tous les coups ?",
            answer: "Depuis le 1er janvier 2023, la réglementation française (décision Arcep) oblige les plateformes de démarchage à appeler depuis des plages de numéros dédiées et connues (01 62, 01 63, 02 70, 02 71, 03 77, 03 78, 04 24, 04 25, 05 68, 05 69, 09 48, 09 49). Silencia bloque l'intégralité de ces plages au niveau du système : les appels ne sonnent jamais. Ce n'est pas un filtre statistique — c'est déterministe."
        ),
        Item(
            question: "Un appel important peut-il être bloqué par erreur ?",
            answer: "Ces plages sont réservées par la réglementation à la prospection commerciale : aucun particulier ne peut vous appeler depuis ces numéros. Si un service utilisait une de ces plages hors prospection, il serait en infraction avec le plan de numérotation — la responsabilité lui incombe."
        ),
        Item(
            question: "Où vont mes données ?",
            answer: "Nulle part. Silencia n'a ni compte, ni serveur, ni outil d'analyse. Le blocage s'exécute entièrement sur votre téléphone, et votre liste personnelle ne quitte jamais l'appareil."
        ),
        Item(
            question: "L'application doit-elle rester ouverte ?",
            answer: "Non. Une fois Silencia activé dans les Réglages iOS, le blocage est assuré par le système en permanence. Vous pouvez oublier l'application — c'est le but."
        ),
        Item(
            question: "Que se passe-t-il si l'Arcep change les plages ?",
            answer: "Les mises à jour des plages sont incluses, à vie, dans les mises à jour gratuites de l'application. « À vie » veut dire à vie."
        )
    ]

    // swiftlint:enable line_length

    var body: some View {
        ZStack {
            Brand.cream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Questions fréquentes")
                        .font(.brandScreenTitle)
                        .foregroundStyle(Brand.ink)
                        .padding(.bottom, 8)
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.question)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Brand.ink)
                            Text(item.answer)
                                .font(.brandSecondary)
                                .lineSpacing(3)
                                .foregroundStyle(Brand.inkMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .card()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
        }
        .tint(Brand.brick)
    }
}

// MARK: - Privacy policy

struct PrivacyPolicyView: View {
    // Long-form French prose reads better unwrapped.
    // swiftlint:disable line_length
    private static let paragraphs: [(title: String, body: String)] = [
        (
            "Aucune donnée collectée",
            "Silencia ne collecte, ne stocke et ne transmet aucune donnée personnelle. Pas de compte, pas de serveur, pas d'outil d'analyse, pas de SDK tiers."
        ),
        (
            "Votre liste reste chez vous",
            "Les numéros et préfixes que vous ajoutez sont enregistrés uniquement sur votre appareil, dans l'espace sécurisé de l'application. Ils ne quittent jamais votre téléphone."
        ),
        (
            "Le blocage est local",
            "La liste des plages Arcep est embarquée dans l'application et transmise au système iOS sur l'appareil. Aucun appel, aucun numéro, aucun journal n'est envoyé à qui que ce soit."
        ),
        (
            "Achat",
            "Silencia s'achète une seule fois, sur l'App Store. Le paiement est traité par Apple : Silencia ne voit ni votre identité, ni votre moyen de paiement. Aucun achat intégré, jamais."
        ),
        (
            "Contact",
            "Pour toute question : support@silencia.app"
        )
    ]

    // swiftlint:enable line_length

    var body: some View {
        ZStack {
            Brand.cream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Confidentialité")
                        .font(.brandScreenTitle)
                        .foregroundStyle(Brand.ink)

                    ForEach(Self.paragraphs, id: \.title) { entry in
                        paragraph(entry.title, entry.body)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
        }
        .tint(Brand.brick)
    }

    private func paragraph(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Brand.ink)
            Text(body)
                .font(.brandSecondary)
                .lineSpacing(3)
                .foregroundStyle(Brand.inkMuted)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppModel())
}
