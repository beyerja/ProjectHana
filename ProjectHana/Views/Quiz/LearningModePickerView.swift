import SwiftUI

/// Mode picker shown when the user taps the "New" tile for the Countries category.
/// Offers Map Quiz or Multiple Choice learning paths.
struct LearningModePickerView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(LanguageManager.self) private var languageManager

    private var newCards: [ReviewCard] { cardStore.newCards(for: .country) }
    private var newCount: Int { newCards.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                NavigationLink {
                    MapLearningQuizView(newCards: newCards, category: .country)
                } label: {
                    modeCard(
                        icon: "map.fill",
                        color: .blue,
                        title: L10n["learn.mode_picker.map.title"],
                        description: L10n["learn.mode_picker.map.desc"]
                    )
                }
                .disabled(newCards.isEmpty)

                NavigationLink {
                    LearningQuizView(newCards: newCards, category: .country)
                } label: {
                    modeCard(
                        icon: "list.bullet.circle.fill",
                        color: .orange,
                        title: L10n["learn.mode_picker.mcq.title"],
                        description: L10n["learn.mode_picker.mcq.desc"]
                    )
                }
                .disabled(newCards.isEmpty)
            }
            .padding()
        }
        .navigationTitle(L10n["learn.mode_picker.title"])
        .inlineNavigationTitle()
        .id(languageManager.current)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("\(newCount)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text(newCount == 1 ? L10n["quiz.cards_due.singular"] : L10n["quiz.cards_due.plural"])
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func modeCard(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(description)
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
        LearningModePickerView()
            .withPreviewStore()
            .environment(LanguageManager.shared)
    }
}
