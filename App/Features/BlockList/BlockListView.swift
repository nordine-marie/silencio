import SilenciaKit
import SwiftUI

/// Screen 07 — the personal block list (F3). Add numbers or bounded prefixes;
/// every outcome of `BlockListLogic.evaluateAdd` gets explicit, friendly feedback
/// ("déjà couvert ✅" being the flagship case).
struct BlockListView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var input = ""
    @State private var feedback: Feedback?
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            Brand.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    Text(
                        "Le démarchage est déjà bloqué automatiquement.\n"
                            + "Ajoutez ici seulement les numéros gênants restants."
                    )
                    .font(.system(size: 13.5))
                    .lineSpacing(3)
                    .foregroundStyle(Brand.inkFaint)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 18)

                    inputField

                    if let feedback {
                        feedbackBanner(feedback)
                            .padding(.top, 14)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if !model.userEntries.isEmpty {
                        Text("Vos ajouts")
                            .font(.brandCaption)
                            .foregroundStyle(Brand.inkFaint)
                            .textCase(.uppercase)
                            .kerning(0.5)
                            .padding(.top, 24)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 4)

                        entriesCard
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.25), value: feedback)
        .animation(.easeInOut(duration: 0.25), value: model.userEntries)
    }

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Brand.brick)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .accessibilityLabel("Retour")
            Text("Mes numéros bloqués")
                .font(.brandHeader)
                .foregroundStyle(Brand.ink)
            Spacer()
        }
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    private var inputField: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Brand.inkFaint)
            TextField("Ajouter un numéro ou un début de numéro", text: $input)
                .font(.brandRow)
                .foregroundStyle(Brand.ink)
                .keyboardType(.phonePad)
                .focused($inputFocused)
                .submitLabel(.done)
            if !input.isEmpty {
                Button("Ajouter", action: submit)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Brand.brick)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 17)
        .card(cornerRadius: 18)
    }

    private var entriesCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(model.userEntries.enumerated()), id: \.element.id) { index, entry in
                if index > 0 {
                    Rectangle().fill(Brand.divider).frame(height: 1)
                }
                entryRow(entry)
            }
        }
        .card()
    }

    private func entryRow(_ entry: BlockEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind == .prefix ? "\(entry.display) · début de numéro" : entry.display)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                Text(entry.kind == .prefix
                    ? "Tous les numéros commençant par \(entry.display)"
                    : "Numéro")
                    .font(.brandCaption)
                    .foregroundStyle(Brand.inkFaint)
            }
            Spacer()
            Button {
                model.removeEntry(entry)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Brand.danger)
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
            .accessibilityLabel("Supprimer \(entry.display)")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: Feedback

    private struct Feedback: Equatable {
        let icon: String
        let title: String
        let detail: String
        let color: Color
        let background: Color
        let border: Color

        /// Green "all good" banner (added / already covered / duplicate).
        static func success(icon: String = "checkmark", _ title: String, _ detail: String) -> Feedback {
            Feedback(
                icon: icon, title: title, detail: detail,
                color: Brand.green, background: Brand.greenBg, border: Brand.greenBorder
            )
        }

        /// Amber "input problem" banner.
        static func warning(icon: String, _ title: String, _ detail: String) -> Feedback {
            Feedback(
                icon: icon, title: title, detail: detail,
                color: Brand.amber, background: Brand.amberBg, border: Brand.amberBorder
            )
        }
    }

    private func submit() {
        let raw = input
        guard !raw.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        switch model.addEntry(raw: raw) {
        case let .added(entry):
            input = ""
            feedback = .success(
                "\(entry.display) · ajouté",
                entry.kind == .prefix
                    ? "Tous les numéros commençant par \(entry.display) sont bloqués."
                    : "Ce numéro est bloqué."
            )
        case let .alreadyCovered(rangeLabel):
            input = ""
            feedback = .success(
                "\(rangeLabel) · déjà couvert",
                "Silencia bloque déjà ces numéros automatiquement."
            )
        case .duplicate:
            feedback = .success(
                "Déjà dans votre liste",
                "Vous avez déjà ajouté ce numéro."
            )
        case .invalid:
            feedback = .warning(
                icon: "questionmark.circle",
                "Numéro non reconnu",
                "Entrez un numéro français (06 12 34 56 78) ou un début de numéro (08 99 70)."
            )
        case .tooBroad:
            feedback = .warning(
                icon: "exclamationmark.triangle",
                "Début de numéro trop court",
                "Indiquez au moins 6 chiffres pour bloquer un début de numéro."
            )
        case .budgetExceeded:
            feedback = .warning(
                icon: "exclamationmark.triangle",
                "Liste pleine",
                "Vous avez atteint le nombre maximum de numéros."
            )
        }
    }

    private func feedbackBanner(_ feedback: Feedback) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: feedback.icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(feedback.color)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(feedback.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Brand.ink)
                Text(feedback.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(feedback.color)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(feedback.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(feedback.border, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        BlockListView()
            .environmentObject(AppModel())
    }
}
