import SwiftUI

struct PilePickerView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(LanguageManager.self) private var languageManager

    let mode: HomeQuizMode
    let category: CardCategory

    private var newCount: Int {
        mode.supportsNew ? cardStore.newCards(for: category).count : 0
    }

    private var pendingCount: Int {
        cardStore.dueCards(for: category).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if newCount > 0 {
                    NavigationLink(value: QuizRoute.quiz(mode: mode, category: category, pile: .new)) {
                        pileCard(
                            title: L10n["home.tile.new"],
                            count: newCount,
                            icon: "plus.circle.fill",
                            color: .orange
                        )
                    }
                }

                if pendingCount > 0 {
                    NavigationLink(value: QuizRoute.quiz(mode: mode, category: category, pile: .pending)) {
                        pileCard(
                            title: L10n["home.tile.pending"],
                            count: pendingCount,
                            icon: "clock.fill",
                            color: .blue
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(L10n[mode.titleKey])
        .inlineNavigationTitle()
        .id(languageManager.current)
    }

    private func pileCard(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(count) \(count == 1 ? L10n["quiz.cards_due.singular"] : L10n["quiz.cards_due.plural"])")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        PilePickerView(mode: .mapQuiz, category: .country)
            .withPreviewStore()
            .environment(LanguageManager.shared)
    }
}
