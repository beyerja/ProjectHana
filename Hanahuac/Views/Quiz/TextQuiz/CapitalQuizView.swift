import SwiftUI

/// "Type the Capital" quiz: shows a country and the user types its capital.
/// Countries-only. Drives both piles:
/// - `.pending` (due cards) → an SM-2 `TextQuizSession`, ending in `QuizSummaryView`.
/// - `.new` (new cards) → a `LearningSession` (3-consecutive-correct graduation),
///   ending in a graduation completion screen.
struct CapitalQuizView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(ProgressStatsStore.self) private var progressStatsStore: ProgressStatsStore?
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let pile: Pile

    @State private var pending: TextQuizSession?
    @State private var learning: LearningSession?
    @State private var inputText = ""
    @State private var hasBuilt = false
    @State private var localAnswerState: TextAnswerState = .unanswered
    @State private var lastWasCorrect = false
    @FocusState private var fieldFocused: Bool

    private var countries: [Country] {
        GeographyDataLoader.shared.countries
    }

    var body: some View {
        content
            .navigationTitle(L10n["capital_quiz.nav.capital"])
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n["capital_quiz.exit"]) { dismiss() } }
            }
            .onAppear(perform: buildIfNeeded)
    }

    @ViewBuilder
    private var content: some View {
        switch pile {
        case .pending: pendingContent
        case .new: newContent
        }
    }

    // MARK: - Pending (SM-2 due)

    @ViewBuilder
    private var pendingContent: some View {
        if let session = pending {
            if session.isFinished {
                QuizSummaryView(
                    reviewed: session.reviewedCount,
                    correct: session.correctCount,
                    nextDue: session.nextDueDate
                )
            } else {
                quizBody(
                    prompt: session.current?.prompt ?? "",
                    answerState: session.answerState,
                    progressText: "\(session.reviewedCount + 1) / \(session.questions.count)",
                    correctCount: session.correctCount,
                    onCheck: { session.checkAnswer($0) },
                    onNext: { advancePending(session) }
                )
            }
        } else {
            nothingDue
        }
    }

    private func advancePending(_ session: TextQuizSession) {
        session.advance()
        progressStatsStore?.recordSnapshot(cards: cardStore.allCards, streak: StreakTracker.currentStreak())
        inputText = ""
        fieldFocused = true
    }

    // MARK: - New (learning / graduation)

    @ViewBuilder
    private var newContent: some View {
        if let session = learning {
            if session.isFinished {
                completionView(graduated: session.graduatedCount)
            } else if let card = session.current {
                let q = capitalQuestion(for: card)
                quizBody(
                    prompt: q?.prompt ?? "",
                    answerState: localAnswerState,
                    progressText: String(
                        format: L10n["learn.graduated_count"],
                        session.graduatedCount, session.totalNewCards
                    ),
                    correctCount: session.graduatedCount,
                    correctAnswerOverride: q?.correctAnswer,
                    onCheck: { checkLearning($0, question: q) },
                    onNext: { advanceLearning(session) }
                )
            } else {
                noNewCards
            }
        } else {
            noNewCards
        }
    }

    private func capitalQuestion(for card: ReviewCard) -> TextQuestion? {
        TextQuizSession.capitalQuestions(
            cards: [card], countries: countries, locale: languageManager.current
        ).first
    }

    private func checkLearning(_ input: String, question: TextQuestion?) {
        guard localAnswerState == .unanswered, let q = question else { return }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchesPrimary = trimmed.caseInsensitiveCompare(q.correctAnswer) == .orderedSame
        let matchesFallback = q.fallbackAnswer.map {
            trimmed.caseInsensitiveCompare($0) == .orderedSame
        } ?? false
        if matchesPrimary || matchesFallback {
            localAnswerState = .correct
            lastWasCorrect = true
        } else {
            localAnswerState = .incorrect(correctAnswer: q.correctAnswer)
            lastWasCorrect = false
        }
    }

    private func advanceLearning(_ session: LearningSession) {
        if lastWasCorrect { session.recordCorrect() } else { session.recordWrong() }
        progressStatsStore?.recordSnapshot(cards: cardStore.allCards, streak: StreakTracker.currentStreak())
        localAnswerState = .unanswered
        inputText = ""
        fieldFocused = true
    }

    // MARK: - Shared quiz body

    private func quizBody(
        prompt: String,
        answerState: TextAnswerState,
        progressText: String,
        correctCount: Int,
        correctAnswerOverride: String? = nil,
        onCheck: @escaping (String) -> Void,
        onNext: @escaping () -> Void
    ) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                HStack {
                    Text(progressText)
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: L10n["capital_quiz.correct_count"], correctCount))
                        .font(.subheadline).foregroundStyle(Theme.Palette.correct)
                }
                Text(prompt)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
                answerSection(
                    answerState: answerState,
                    correctAnswerOverride: correctAnswerOverride,
                    onCheck: onCheck,
                    onNext: onNext
                )
                Spacer(minLength: 0)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func answerSection(
        answerState: TextAnswerState,
        correctAnswerOverride: String?,
        onCheck: @escaping (String) -> Void,
        onNext: @escaping () -> Void
    ) -> some View {
        switch answerState {
        case .unanswered:
            VStack(spacing: 16) {
                TextField(L10n["capital_quiz.placeholder"], text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                    .onSubmit { onCheck(inputText) }
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .neverAutocapitalize()
                Button(L10n["capital_quiz.check"]) { onCheck(inputText) }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        inputText.isEmpty ? Color.secondary.opacity(0.3) : Theme.Palette.accent,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(.white)
                    .disabled(inputText.isEmpty)
            }
            .onAppear { fieldFocused = true }
        case .correct:
            feedback(text: L10n["capital_quiz.feedback.correct"], color: Theme.Palette.correct, onNext: onNext)
        case let .incorrect(correctAnswer):
            feedback(
                text: "\(L10n["capital_quiz.feedback.wrong_prefix"]) \(correctAnswerOverride ?? correctAnswer)",
                color: Theme.Palette.wrong, onNext: onNext
            )
        }
    }

    private func feedback(text: String, color: Color, onNext: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Text(text)
                .font(.headline)
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            Button(L10n["capital_quiz.next"]) { onNext() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Empty / completion states

    private var nothingDue: some View {
        ContentUnavailableView(
            L10n["capital_quiz.nothing_due_title"],
            systemImage: "checkmark.circle",
            description: Text(L10n["capital_quiz.nothing_due_desc"])
        )
    }

    private var noNewCards: some View {
        ContentUnavailableView(
            L10n["learn.no_cards_title"],
            systemImage: "checkmark.circle",
            description: Text(L10n["learn.no_cards_desc"])
        )
    }

    private func completionView(graduated: Int) -> some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.Palette.accent)
                Text(L10n["learn.complete_title"]).font(.title.bold())
                Text(L10n["learn.complete_desc"])
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            HStack {
                Text(L10n["learn.cards_graduated"]).foregroundStyle(.secondary)
                Spacer()
                Text("\(graduated)").bold()
            }
            .padding()
            .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            Spacer()
            Button(L10n["learn.done"]) { dismiss() }
                .font(.headline).frame(maxWidth: .infinity).padding()
                .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white).padding(.horizontal).padding(.bottom)
        }
        .navigationTitle(L10n["learn.results"])
        .inlineNavigationTitle()
        .navigationBarBackButtonHidden()
    }

    // MARK: - Build

    private func buildIfNeeded() {
        guard !hasBuilt else { return }
        hasBuilt = true
        switch pile {
        case .pending:
            let due = cardStore.dueCards(for: .country)
            let questions = TextQuizSession.capitalQuestions(
                cards: due, countries: countries, locale: languageManager.current
            )
            pending = questions.isEmpty ? nil : TextQuizSession(questions: questions)
        case .new:
            let newCards = cardStore.newCards(for: .country)
            learning = LearningSession(newCards: newCards, category: .country, store: UserDefaultsActiveSetStore())
        }
    }
}

#Preview {
    NavigationStack {
        CapitalQuizView(pile: .pending)
            .withPreviewStore()
            .environment(LanguageManager.shared)
    }
}
