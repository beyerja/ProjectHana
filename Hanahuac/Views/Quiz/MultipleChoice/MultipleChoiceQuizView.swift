import SwiftUI

struct MultipleChoiceQuizView: View {
    @Environment(CardStoreProvider.self) private var cardStoreProvider
    @Environment(ProgressStatsStore.self) private var progressStatsStore: ProgressStatsStore?

    /// This view quizzes the Multiple Choice pending pile, so it reads/writes the `multipleChoice`
    /// store.
    private var cardStore: CardStore {
        cardStoreProvider.store(for: .multipleChoice)
    }

    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let category: CardCategory

    @State private var session: MultipleChoiceSession?
    @State private var isAdvancing = false

    var body: some View {
        Group {
            if let session {
                if session.isFinished {
                    QuizSummaryView(
                        reviewed: session.reviewedCount,
                        correct: session.correctCount,
                        nextDue: session.nextDueDate
                    )
                } else {
                    quizBody(session: session)
                }
            } else {
                ContentUnavailableView(
                    L10n["mcq_quiz.nothing_due_title"],
                    systemImage: "checkmark.circle",
                    description: Text(L10n["mcq_quiz.nothing_due_desc"])
                )
            }
        }
        .navigationTitle(navigationTitle)
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(L10n["mcq_quiz.exit"]) { dismiss() } }
        }
        .onAppear { buildSession() }
    }

    // MARK: – Quiz body

    private func quizBody(session: MultipleChoiceSession) -> some View {
        VStack(spacing: 0) {
            progressHeader(session: session)
                .padding(.horizontal)
                .padding(.top)

            ScrollView {
                VStack(spacing: 20) {
                    promptCard(session: session)
                    optionButtons(session: session)
                }
                .padding()
            }
        }
    }

    private func progressHeader(session: MultipleChoiceSession) -> some View {
        HStack {
            Text("\(session.reviewedCount + 1) / \(session.questions.count)")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(String(format: L10n["mcq_quiz.correct_count"], session.correctCount))
                .font(.subheadline).foregroundStyle(Theme.Palette.correct)
        }
    }

    private func promptCard(session: MultipleChoiceSession) -> some View {
        Text(session.current?.prompt ?? "")
            .font(.title3.bold())
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
    }

    private func optionButtons(session: MultipleChoiceSession) -> some View {
        VStack(spacing: 12) {
            ForEach(session.current?.options ?? []) { option in
                Button {
                    guard !isAdvancing else { return }
                    session.select(optionID: option.id)
                    scheduleAdvance(session: session)
                } label: {
                    Text(option.label)
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            buttonColor(for: option, in: session),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(buttonForeground(for: option, in: session))
                }
                .disabled(session.answerState != .unanswered || isAdvancing)
            }
        }
    }

    // MARK: – Styling helpers

    private func buttonColor(for option: MCQOption, in session: MultipleChoiceSession) -> Color {
        switch session.answerState {
        case .unanswered:
            return Theme.Palette.accent.opacity(0.15)
        case let .correct(id):
            return option.id == id ? Theme.Palette.correct : Theme.Palette.accent.opacity(0.1)
        case let .incorrect(chosenID, correctID):
            if option.id == chosenID { return Theme.Palette.wrong }
            if option.id == correctID { return Theme.Palette.correct }
            return Theme.Palette.accent.opacity(0.1)
        }
    }

    private func buttonForeground(for option: MCQOption, in session: MultipleChoiceSession) -> Color {
        switch session.answerState {
        case .unanswered: return Theme.Palette.accent
        case let .correct(id): return option.id == id ? .white : .secondary
        case let .incorrect(chosenID, correctID):
            if option.id == chosenID || option.id == correctID { return .white }
            return .secondary
        }
    }

    // MARK: – Auto-advance

    private func scheduleAdvance(session: MultipleChoiceSession) {
        isAdvancing = true
        let delay: UInt64 = {
            if case .correct = session.answerState { return 1_500_000_000 }
            return 2_000_000_000
        }()
        Task {
            try? await Task.sleep(nanoseconds: delay)
            session.advance()
            cardStore.persistCardChanges()
            progressStatsStore?.recordSnapshot(
                allCards: cardStoreProvider.allCards,
                modeCards: cardStore.allCards,
                mode: .multipleChoice,
                streak: StreakTracker.currentStreak(language: cardStore.language)
            )
            isAdvancing = false
        }
    }

    // MARK: – Session builder

    private func buildSession() {
        let due = cardStore.dueCards(for: category)
        guard !due.isEmpty else { session = nil
            return
        }
        let geo = GeographyDataLoader.shared
        let locale = languageManager.current
        let questions: [MCQQuestion] = switch category {
        case .country:
            MultipleChoiceSession.countryCapitalQuestions(
                cards: due, countries: geo.countries, locale: locale
            )
        case .river:
            MultipleChoiceSession.continentQuestions(
                cards: due, facts: geo.rivers,
                factID: \.id, factName: \.name, factContinent: \.continent,
                categoryLabel: "river", locale: locale,
                factLocalizedName: { $0.localizedName(for: $1) }
            )
        case .mountain:
            MultipleChoiceSession.continentQuestions(
                cards: due, facts: geo.mountains,
                factID: \.id, factName: \.name, factContinent: \.continent,
                categoryLabel: "mountain range", locale: locale,
                factLocalizedName: { $0.localizedName(for: $1) }
            )
        case .sea:
            MultipleChoiceSession.seaIdentificationQuestions(
                cards: due, seas: geo.seas, locale: locale
            )
        }
        session = questions.isEmpty ? nil : MultipleChoiceSession(questions: questions)
    }

    private var navigationTitle: String {
        switch category {
        case .country: L10n["mcq_quiz.nav.country"]
        case .river: L10n["mcq_quiz.nav.river"]
        case .mountain: L10n["mcq_quiz.nav.mountain"]
        case .sea: L10n["mcq_quiz.nav.sea"]
        }
    }
}

#Preview {
    NavigationStack {
        MultipleChoiceQuizView(category: .country)
            .withPreviewStore()
    }
}
