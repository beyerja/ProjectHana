import SwiftUI

struct LearningQuizView: View {
    @Environment(CardStoreProvider.self) private var cardStoreProvider
    @Environment(\.dismiss) private var dismiss

    /// The Multiple Choice "learn new cards" flow, so it persists into the `multipleChoice` store.
    private var cardStore: CardStore {
        cardStoreProvider.store(for: .multipleChoice)
    }

    @State private var session: LearningSession
    @State private var currentQuestion: MCQQuestion?
    @State private var answerState: MCQAnswerState = .unanswered
    @State private var isAdvancing = false
    /// Owned handle for the auto-advance Task so it can be cancelled when the view is torn down
    /// (system back chevron / swipe-back). Prevents the dismiss-while-advancing crash (AC2).
    @State private var advanceTask: Task<Void, Never>?

    /// Completion-icon point size that scales with Dynamic Type (relative to largeTitle).
    @ScaledMetric(relativeTo: .largeTitle) private var completionIconSize: CGFloat = 64

    private let geo = GeographyDataLoader.shared

    init(newCards: [ReviewCard], category: CardCategory? = nil) {
        // The active set is per-language AND per-mode; scope it to the active language and this view's
        // mode (Multiple Choice).
        let language = LanguageManager.shared.current.rawValue
        let store: ActiveSetStore? = category != nil
            ? UserDefaultsActiveSetStore(language: language, mode: .multipleChoice)
            : nil
        _session = State(initialValue: LearningSession(newCards: newCards, category: category, store: store))
    }

    var body: some View {
        Group {
            if session.isFinished {
                completionView
            } else if let question = currentQuestion {
                quizBody(question: question)
            } else {
                ContentUnavailableView(
                    L10n["learn.no_cards_title"],
                    systemImage: "checkmark.circle",
                    description: Text(L10n["learn.no_cards_desc"])
                )
            }
        }
        .navigationTitle(L10n["learn.title"])
        .inlineNavigationTitle()
        .onAppear { refreshQuestion() }
        .onDisappear {
            // Cancel the in-flight advance so its post-sleep persist never runs against a torn-down
            // environment when the user exits via the system back chevron (AC2).
            advanceTask?.cancel()
            advanceTask = nil
            isAdvancing = false
        }
    }

    // MARK: – Quiz body

    private func quizBody(question: MCQQuestion) -> some View {
        VStack(spacing: 0) {
            progressHeader
                .padding(.horizontal)
                .padding(.top)

            ScrollView {
                VStack(spacing: 20) {
                    promptCard(question: question)
                    optionButtons(question: question)
                }
                .padding()
            }
        }
    }

    private var progressHeader: some View {
        HStack {
            Text(String(format: L10n["learn.graduated_count"], session.graduatedCount, session.totalNewCards))
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(String(format: L10n["learn.active_count"], session.activeSet.count))
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(format: L10n["a11y.graduated"], session.graduatedCount, session.totalNewCards)
        )
        .accessibilityValue(String(format: L10n["a11y.active"], session.activeSet.count))
    }

    private func promptCard(question: MCQQuestion) -> some View {
        Text(question.prompt)
            .font(.title3.bold())
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel(L10n["a11y.prompt.label"])
            .accessibilityValue(question.prompt)
    }

    private func optionButtons(question: MCQQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                Button {
                    guard !isAdvancing else { return }
                    handleAnswer(option: option, question: question)
                } label: {
                    Text(option.label)
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonColor(for: option), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(buttonForeground(for: option))
                }
                .disabled(answerState != .unanswered || isAdvancing)
                .accessibilityIdentifier("quiz.answer.\(index)")
                .accessibilityLabel(option.label)
                .accessibilityValue(optionStateValue(for: option))
                .accessibilityAddTraits(isSelected(option) ? .isSelected : [])
                .accessibilityHint(answerState == .unanswered ? L10n["a11y.option.hint"] : "")
            }
        }
    }

    /// Whether VoiceOver should mark this option as selected — the option the user chose, regardless
    /// of correctness. Mirrors `answerState` so state is conveyed via trait, not color alone.
    private func isSelected(_ option: MCQOption) -> Bool {
        switch answerState {
        case .unanswered:
            false
        case let .correct(id):
            option.id == id
        case let .incorrect(chosenID, _):
            option.id == chosenID
        }
    }

    /// The spoken state for an option after an answer is locked in: correct / incorrect / nothing
    /// while unanswered. Derived from `answerState` (the same source as `buttonColor`).
    private func optionStateValue(for option: MCQOption) -> String {
        switch answerState {
        case .unanswered:
            return ""
        case let .correct(id):
            return option.id == id ? L10n["a11y.state.correct"] : ""
        case let .incorrect(chosenID, correctID):
            if option.id == chosenID {
                return L10n["a11y.state.incorrect"]
            }
            if option.id == correctID {
                return L10n["a11y.state.correct"]
            }
            return ""
        }
    }

    // MARK: – Answer handling

    private func handleAnswer(option: MCQOption, question: MCQQuestion) {
        let correctOpt = question.options.first(where: \.isCorrect)!
        if option.isCorrect {
            answerState = .correct(chosenID: option.id)
            scheduleAdvance(wasCorrect: true)
        } else {
            answerState = .incorrect(chosenID: option.id, correctID: correctOpt.id)
            scheduleAdvance(wasCorrect: false)
        }
    }

    private func scheduleAdvance(wasCorrect: Bool) {
        isAdvancing = true
        let delay: UInt64 = wasCorrect ? 1_000_000_000 : 2_000_000_000
        advanceTask = Task {
            let didRun = await QuizAdvanceScheduler.run(afterNanoseconds: delay) {
                if wasCorrect {
                    session.recordCorrect()
                } else {
                    session.recordWrong()
                }
                cardStore.persistCardChanges()
            }
            // Only mutate view state if the advance actually ran (i.e. the exit did not cancel us).
            if didRun {
                answerState = .unanswered
                isAdvancing = false
                refreshQuestion()
            }
        }
    }

    private func refreshQuestion() {
        guard let card = session.current else { currentQuestion = nil
            return
        }
        currentQuestion = makeQuestion(for: card)
    }

    // MARK: – Completion

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: completionIconSize))
                    .foregroundStyle(Theme.Palette.accent)
                    .accessibilityHidden(true)
                Text(L10n["learn.complete_title"])
                    .font(.title.bold())
                Text(L10n["learn.complete_desc"])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack {
                Text(L10n["learn.cards_graduated"]).foregroundStyle(.secondary)
                Spacer()
                Text("\(session.graduatedCount)").bold()
            }
            .padding()
            .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .accessibilityElement(children: .combine)

            Spacer()

            Button(L10n["learn.done"]) { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .padding(.horizontal)
                .padding(.bottom)
                .accessibilityHint(L10n["a11y.done.hint"])
        }
        .navigationTitle(L10n["learn.results"])
        .inlineNavigationTitle()
        .navigationBarBackButtonHidden()
    }

    // MARK: – Button styling

    private func buttonColor(for option: MCQOption) -> Color {
        switch answerState {
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

    private func buttonForeground(for option: MCQOption) -> Color {
        switch answerState {
        case .unanswered:
            return Theme.Palette.accent
        case let .correct(id):
            return option.id == id ? .white : .secondary
        case let .incorrect(chosenID, correctID):
            if option.id == chosenID || option.id == correctID { return .white }
            return .secondary
        }
    }

    // MARK: – Question factory

    private func makeQuestion(for card: ReviewCard) -> MCQQuestion? {
        // Resolve the active app language so the new-card MC prompt + feature names localize the same
        // way the review MC quiz does (MultipleChoiceQuizView.buildSession); without this the factory
        // methods default to `.en` and the prompt leaks English even when the UI is e.g. Spanish.
        let locale = LanguageManager.shared.current
        switch card.cardCategory {
        case .country:
            return MultipleChoiceSession.countryCapitalQuestions(
                cards: [card], countries: geo.countries, locale: locale
            ).first
        case .river:
            return MultipleChoiceSession.continentQuestions(
                cards: [card], facts: geo.rivers,
                factID: \.id, factName: \.name, factContinent: \.continent,
                categoryLabel: "river", locale: locale,
                factLocalizedName: { $0.localizedName(for: $1) }
            ).first
        case .mountain:
            return MultipleChoiceSession.continentQuestions(
                cards: [card], facts: geo.mountains,
                factID: \.id, factName: \.name, factContinent: \.continent,
                categoryLabel: "mountain range", locale: locale,
                factLocalizedName: { $0.localizedName(for: $1) }
            ).first
        case .sea:
            return MultipleChoiceSession.seaIdentificationQuestions(
                cards: [card], seas: geo.seas, locale: locale
            ).first
        }
    }
}
