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

                        VStack(spacing: 12) {
                            BrandMark(height: 22, color: Brand.inkFaint)
                            Text("Silencia \(appVersion) · Fait en France · Aucune donnée collectée")
                                .font(.brandCaption)
                                .foregroundStyle(Brand.inkFaint)
                        }
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
            answer: "Depuis le 1er janvier 2023, la loi française oblige les sociétés de démarchage à vous appeler depuis des séries de numéros bien précises et connues (01 62, 01 63, 02 70, 02 71, 03 77, 03 78, 04 24, 04 25, 05 68, 05 69, 09 48, 09 49). Silencia bloque toutes ces séries directement sur votre téléphone : ces appels ne sonnent jamais. Ce n'est pas une question de chance, c'est une certitude."
        ),
        Item(
            question: "Un appel important peut-il être bloqué par erreur ?",
            answer: "Non. Ces séries de numéros sont réservées par la loi au démarchage commercial : aucun proche, aucun médecin, aucun service public ne peut vous appeler depuis ces numéros. Si une entreprise s'en servait pour autre chose, c'est elle qui serait en faute, pas vous."
        ),
        Item(
            question: "Où vont mes données ?",
            answer: "Nulle part. Silencia ne crée aucun compte et n'envoie rien sur internet. Tout se passe sur votre téléphone, et votre liste personnelle ne le quitte jamais."
        ),
        Item(
            question: "L'application doit-elle rester ouverte ?",
            answer: "Non. Une fois Silencia activé dans les Réglages de votre iPhone, la protection reste active en permanence, même quand l'application est fermée. Vous pouvez l'oublier : c'est justement le but."
        ),
        Item(
            question: "Que se passe-t-il si ces numéros changent ?",
            answer: "Si la liste officielle évolue, la mise à jour est incluse gratuitement, à vie, dans l'application. « À vie » veut dire à vie."
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
            "Silencia ne collecte, n'enregistre et ne transmet aucune donnée personnelle. Pas de compte, aucun envoi sur internet, aucun outil de suivi."
        ),
        (
            "Votre liste reste chez vous",
            "Les numéros que vous ajoutez sont enregistrés uniquement sur votre téléphone, dans l'espace protégé de l'application. Ils ne le quittent jamais."
        ),
        (
            "Tout se passe sur votre téléphone",
            "La liste officielle des numéros de démarchage est incluse dans l'application et transmise directement à votre iPhone. Aucun appel, aucun numéro, aucune trace n'est envoyé à qui que ce soit."
        ),
        (
            "Achat",
            "Silencia s'achète une seule fois, sur l'App Store. Le paiement est géré par Apple : Silencia ne connaît ni votre identité, ni votre moyen de paiement. Aucun paiement supplémentaire, jamais."
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
