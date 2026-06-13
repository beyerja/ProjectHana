import SwiftUI

struct HomeView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(LanguageManager.self) private var languageManager
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 28) {
                    categorySections
                    progressLink
                }
                .padding()
            }
            .navigationTitle("ProjectHana")
            .largeNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        LanguagePickerView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .navigationDestination(for: QuizRoute.self) { route in
                quizRouteView(route)
            }
        }
        .id(languageManager.current)
    }

    // MARK: – Category sections

    private var categorySections: some View {
        VStack(spacing: 24) {
            categorySection(
                name: L10n["home.category.countries"],
                icon: "globe", color: .blue, category: .country,
                modes: [.mapQuiz, .multipleChoice, .typeCapital, .nameCountry]
            )
            categorySection(
                name: L10n["home.category.rivers"],
                icon: "water.waves", color: .cyan, category: .river,
                modes: [.multipleChoice]
            )
            categorySection(
                name: L10n["home.category.mountains"],
                icon: "mountain.2", color: .brown, category: .mountain,
                modes: [.multipleChoice]
            )
            categorySection(
                name: L10n["home.category.seas"],
                icon: "drop.fill", color: .teal, category: .sea,
                modes: [.multipleChoice]
            )
        }
    }

    private func categorySection(
        name: String, icon: String, color: Color,
        category: CardCategory, modes: [HomeQuizMode]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(name, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
                .padding(.bottom, 2)

            ForEach(modes, id: \.self) { mode in
                quizModeButton(mode: mode, category: category)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Quiz mode buttons

    private func quizModeButton(mode: HomeQuizMode, category: CardCategory) -> some View {
        let newCount = mode.supportsNew ? cardStore.newCards(for: category).count : 0
        let pendingCount = cardStore.dueCards(for: category).count
        let isEnabled = newCount > 0 || pendingCount > 0

        return Button {
            navigateTo(mode: mode, category: category, newCount: newCount, pendingCount: pendingCount)
        } label: {
            modeRowLabel(mode: mode, newCount: newCount, pendingCount: pendingCount, isEnabled: isEnabled)
        }
        .disabled(!isEnabled)
    }

    private func navigateTo(mode: HomeQuizMode, category: CardCategory, newCount: Int, pendingCount: Int) {
        if newCount > 0 && pendingCount > 0 {
            navigationPath.append(QuizRoute.pilePicker(mode: mode, category: category))
        } else if newCount > 0 {
            navigationPath.append(QuizRoute.quiz(mode: mode, category: category, pile: .new))
        } else if pendingCount > 0 {
            navigationPath.append(QuizRoute.quiz(mode: mode, category: category, pile: .pending))
        }
    }

    private func modeRowLabel(mode: HomeQuizMode, newCount: Int, pendingCount: Int, isEnabled: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: mode.icon)
                .font(.title3)
                .foregroundStyle(isEnabled ? mode.color : .secondary)
                .frame(width: 38, height: 38)
                .background(
                    (isEnabled ? mode.color : Color.secondary).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 9)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n[mode.titleKey])
                    .font(.subheadline).bold()
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                HStack(spacing: 6) {
                    if newCount > 0 {
                        countPill(label: L10n["home.tile.new"], count: newCount, color: .orange)
                    }
                    if pendingCount > 0 {
                        countPill(label: L10n["home.tile.pending"], count: pendingCount, color: .blue)
                    }
                }
            }

            Spacer()

            if isEnabled {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func countPill(label: String, count: Int, color: Color) -> some View {
        Text("\(label): \(count)")
            .font(.caption)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
            .foregroundStyle(color)
    }

    // MARK: – Navigation destinations

    @ViewBuilder
    private func quizRouteView(_ route: QuizRoute) -> some View {
        switch route {
        case .pilePicker(let mode, let category):
            PilePickerView(mode: mode, category: category)
        case .quiz(let mode, let category, let pile):
            directQuizView(mode: mode, category: category, pile: pile)
        }
    }

    @ViewBuilder
    private func directQuizView(mode: HomeQuizMode, category: CardCategory, pile: Pile) -> some View {
        switch (mode, pile) {
        case (.mapQuiz, .new):
            MapLearningQuizView(newCards: cardStore.newCards(for: category), category: category)
        case (.mapQuiz, .pending):
            MapQuizView(category: category)
        case (.multipleChoice, .new):
            LearningQuizView(newCards: cardStore.newCards(for: category), category: category)
        case (.multipleChoice, .pending):
            MultipleChoiceQuizView(category: category)
        case (.typeCapital, _):
            CapitalQuizView(mode: .capitalOfCountry)
        case (.nameCountry, _):
            CapitalQuizView(mode: .countryOfCapital)
        }
    }

    // MARK: – Progress link

    private var progressLink: some View {
        NavigationLink {
            StatsView()
        } label: {
            Label(L10n["home.view_progress"], systemImage: "chart.bar.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    HomeView()
        .withPreviewStore()
        .environment(LanguageManager.shared)
}
