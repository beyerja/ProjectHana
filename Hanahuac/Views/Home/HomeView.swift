import SwiftUI

struct HomeView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(LanguageManager.self) private var languageManager
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 28) {
                    HanahuacWordmark()
                        .padding(.top, 8)
                    categorySections
                    progressLink
                }
                .padding(20)
            }
            .background(Theme.Palette.canvas.ignoresSafeArea())
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                }
            }
            .navigationDestination(for: QuizRoute.self) { route in
                quizRouteView(route)
            }
        }
        .tint(Theme.Palette.accent)
        .id(languageManager.current)
    }

    // MARK: – Category sections

    private var categorySections: some View {
        VStack(spacing: 24) {
            categorySection(
                name: L10n["home.category.countries"],
                icon: "globe.americas.fill", color: Theme.Palette.country, category: .country,
                modes: [.mapQuiz, .multipleChoice, .typeCapital, .nameCountry]
            )
            categorySection(
                name: L10n["home.category.rivers"],
                icon: "water.waves", color: Theme.Palette.river, category: .river,
                modes: [.mapQuiz, .multipleChoice]
            )
            categorySection(
                name: L10n["home.category.mountains"],
                icon: "mountain.2.fill", color: Theme.Palette.mountain, category: .mountain,
                modes: [.mapQuiz, .multipleChoice]
            )
            categorySection(
                name: L10n["home.category.seas"],
                icon: "drop.fill", color: Theme.Palette.sea, category: .sea,
                modes: [.mapQuiz, .multipleChoice]
            )
        }
    }

    private func categorySection(
        name: String, icon: String, color: Color,
        category: CardCategory, modes: [HomeQuizMode]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(name, systemImage: icon)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(color)
                .padding(.leading, 4)

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
        .buttonStyle(PressableCardButtonStyle())
        .disabled(!isEnabled)
    }

    private func navigateTo(mode: HomeQuizMode, category: CardCategory, newCount: Int, pendingCount: Int) {
        if newCount > 0, pendingCount > 0 {
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
                .foregroundStyle(isEnabled ? mode.color : Theme.Palette.neutral)
                .frame(width: 42, height: 42)
                .background(
                    (isEnabled ? mode.color : Theme.Palette.neutral).opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n[mode.titleKey])
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(isEnabled ? Theme.Palette.textPrimary : Theme.Palette.textSecondary)

                HStack(spacing: 6) {
                    if newCount > 0 {
                        countPill(label: L10n["home.tile.new"], count: newCount, color: Theme.Palette.new)
                    }
                    if pendingCount > 0 {
                        countPill(label: L10n["home.tile.pending"], count: pendingCount, color: Theme.Palette.pending)
                    }
                    if !isEnabled {
                        Text(L10n["home.tile.all_done"])
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                }
            }

            Spacer()

            if isEnabled {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textSecondary.opacity(0.6))
            }
        }
        .padding(14)
        .background(
            Theme.Palette.surface,
            in: RoundedRectangle(cornerRadius: Theme.Metrics.tileRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.tileRadius, style: .continuous)
                .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
        )
        .shadow(color: Theme.cardShadow, radius: isEnabled ? 8 : 0, x: 0, y: 4)
        .opacity(isEnabled ? 1 : 0.7)
    }

    private func countPill(label: String, count: Int, color: Color) -> some View {
        Text("\(label) \(count)")
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    // MARK: – Navigation destinations

    @ViewBuilder
    private func quizRouteView(_ route: QuizRoute) -> some View {
        switch route {
        case let .pilePicker(mode, category):
            PilePickerView(mode: mode, category: category)
        case let .quiz(mode, category, pile):
            directQuizView(mode: mode, category: category, pile: pile)
                .background(Theme.Palette.canvas.ignoresSafeArea())
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
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.Palette.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Theme.Palette.accent, Theme.Palette.accentDeep],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                )
                .shadow(color: Theme.Palette.accent.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PressableCardButtonStyle())
    }
}

/// Subtle press-scale interaction used by the home cards.
struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
        .withPreviewStore()
        .environment(LanguageManager.shared)
        .environment(SyncCoordinator(
            availability: FixedICloudAvailabilityProvider(isICloudAccountAvailable: false)
        ))
}
