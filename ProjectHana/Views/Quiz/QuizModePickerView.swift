import SwiftUI

struct QuizModePickerView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    private var dueCount: Int { cardStore.dueCards(for: .country).count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                NavigationLink {
                    MapQuizView(category: .country)
                } label: {
                    modeCard(
                        icon: "map.fill",
                        color: .blue,
                        title: L10n["quiz.mode.map_tap.title"],
                        description: L10n["quiz.mode.map_tap.desc"]
                    )
                }

                NavigationLink {
                    CapitalQuizView(mode: .capitalOfCountry)
                } label: {
                    modeCard(
                        icon: "building.columns.fill",
                        color: .purple,
                        title: L10n["quiz.mode.type_capital.title"],
                        description: L10n["quiz.mode.type_capital.desc"]
                    )
                }

                NavigationLink {
                    CapitalQuizView(mode: .countryOfCapital)
                } label: {
                    modeCard(
                        icon: "globe.europe.africa.fill",
                        color: .indigo,
                        title: L10n["quiz.mode.name_country.title"],
                        description: L10n["quiz.mode.name_country.desc"]
                    )
                }

                NavigationLink {
                    MultipleChoiceQuizView(category: .country)
                } label: {
                    modeCard(
                        icon: "list.bullet.circle.fill",
                        color: .orange,
                        title: L10n["quiz.mode.multiple_choice.title"],
                        description: L10n["quiz.mode.multiple_choice.desc"]
                    )
                }
            }
            .padding()
        }
        .navigationTitle(L10n["home.category.countries"])
        .inlineNavigationTitle()
        // Re-render when language changes.
        .id(languageManager.current)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("\(dueCount)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text(dueCount == 1 ? L10n["quiz.cards_due.singular"] : L10n["quiz.cards_due.plural"])
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
        QuizModePickerView()
            .withPreviewStore()
            .environment(LanguageManager.shared)
    }
}
