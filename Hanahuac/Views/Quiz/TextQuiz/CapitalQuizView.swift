import SwiftUI

/// "Type the Capital" quiz: shows a country and the user types its capital.
/// Countries-only. Drives both piles:
/// - `.pending` (due cards) → an SM-2 `TextQuizSession`, ending in `QuizSummaryView`.
/// - `.new` (new cards) → a `LearningSession` (3-consecutive-correct graduation),
///   ending in a graduation completion screen.
struct CapitalQuizView: View {
    @Environment(CardStoreProvider.self) private var cardStoreProvider
    @Environment(ProgressStatsStore.self) private var progressStatsStore: ProgressStatsStore?
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let pile: Pile

    /// "Type the Capital" is its own quiz mode, so it reads/writes the `typeCapital` store.
    private var cardStore: CardStore {
        cardStoreProvider.store(for: .typeCapital)
    }

    @State private var pending: TextQuizSession?
    @State private var learning: LearningSession?
    @State private var inputText = ""
    @State private var hasBuilt = false
    @State private var localAnswerState: TextAnswerState = .unanswered
    @State private var lastWasCorrect = false
    @FocusState private var fieldFocused: Bool

    /// Completion-icon point size that scales with Dynamic Type (relative to largeTitle).
    @ScaledMetric(relativeTo: .largeTitle) private var completionIconSize: CGFloat = 64

    private var countries: [Country] {
        GeographyDataLoader.shared.countries
    }

    var body: some View {
        content
            .navigationTitle(L10n["capital_quiz.nav.capital"])
            .inlineNavigationTitle()
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
        cardStore.persistCardChanges()
        progressStatsStore?.recordSnapshot(
            allCards: cardStoreProvider.allCards,
            modeCards: cardStore.allCards,
            mode: .typeCapital,
            streak: StreakTracker.currentStreak(language: cardStore.language)
        )
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
        cardStore.persistCardChanges()
        progressStatsStore?.recordSnapshot(
            allCards: cardStoreProvider.allCards,
            modeCards: cardStore.allCards,
            mode: .typeCapital,
            streak: StreakTracker.currentStreak(language: cardStore.language)
        )
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
        // Prompt + progress scroll in the top region; the answer field and action button are pinned
        // to the bottom via a `.safeAreaInset(edge: .bottom)` so SwiftUI's keyboard avoidance lifts
        // them together and the "Verificar"/"Siguiente" button is never pushed under the keyboard (or
        // the iOS multilingual-keyboard onboarding card). `.scrollDismissesKeyboard(.interactively)`
        // keeps the scrolling prompt reachable while the keyboard is up.
        ScrollView {
            VStack(spacing: 28) {
                HStack {
                    Text(progressText)
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: L10n["capital_quiz.correct_count"], correctCount))
                        .font(.subheadline).foregroundStyle(Theme.Palette.correct)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(progressText)
                .accessibilityValue(String(format: L10n["a11y.score"], correctCount))
                Text(prompt)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel(L10n["a11y.prompt.label"])
                    .accessibilityValue(prompt)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            answerSection(
                answerState: answerState,
                correctAnswerOverride: correctAnswerOverride,
                onCheck: onCheck,
                onNext: onNext
            )
            .padding()
            .background(.bar)
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
                    .accessibilityIdentifier("quiz.input")
                    .accessibilityLabel(L10n["a11y.answer_field.label"])
                    .accessibilityHint(L10n["a11y.answer_field.hint"])
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
                    .accessibilityIdentifier("quiz.submit")
                    .accessibilityHint(L10n["a11y.check.hint"])
            }
            .onAppear { fieldFocused = true }
        case .correct:
            feedback(
                text: L10n["capital_quiz.feedback.correct"],
                color: Theme.Palette.correct,
                stateLabel: L10n["a11y.feedback.correct"],
                onNext: onNext
            )
        case let .incorrect(correctAnswer):
            feedback(
                text: "\(L10n["capital_quiz.feedback.wrong_prefix"]) \(correctAnswerOverride ?? correctAnswer)",
                color: Theme.Palette.wrong,
                stateLabel: L10n["a11y.feedback.incorrect"],
                onNext: onNext
            )
        }
    }

    private func feedback(
        text: String,
        color: Color,
        stateLabel: String,
        onNext: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Text(text)
                .font(.headline)
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(stateLabel). \(text)")
                .accessibilityAddTraits(.isStaticText)
            Button(L10n["capital_quiz.next"]) { onNext() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .accessibilityHint(L10n["a11y.next.hint"])
        }
    }

    // MARK: - Empty / completion states

    /// Advance the session and record today's progress rollup (no-op when no stats store is injected,
    /// e.g. in previews).
    private func advance(_ session: TextQuizSession) {
        session.advance()
        progressStatsStore?.recordSnapshot(
            allCards: cardStoreProvider.allCards,
            modeCards: cardStore.allCards,
            mode: .typeCapital,
            streak: StreakTracker.currentStreak(language: cardStore.language)
        )
    }

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
                    .font(.system(size: completionIconSize))
                    .foregroundStyle(Theme.Palette.accent)
                    .accessibilityHidden(true)
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
            .accessibilityElement(children: .combine)
            Spacer()
            Button(L10n["learn.done"]) { dismiss() }
                .font(.headline).frame(maxWidth: .infinity).padding()
                .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white).padding(.horizontal).padding(.bottom)
                .accessibilityHint(L10n["a11y.done.hint"])
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
            // The active set is per-language AND per-mode; scope it to the active language and this
            // view's mode (Type the Capital).
            let store = UserDefaultsActiveSetStore(language: cardStore.language, mode: .typeCapital)
            learning = LearningSession(newCards: newCards, category: .country, store: store)
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
