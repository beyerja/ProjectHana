import MapKit
import SwiftUI

/// The map-pin "Name that place" quiz: the current feature is shown pinned on the
/// map and the user types its name. Works for every category (countries, rivers,
/// mountains, seas) by driving the generic `MappableFeature` machinery.
///
/// Two piles, mirroring the other quiz surfaces:
/// - `.pending` (due cards) → an SM-2 `TextQuizSession`, ending in `QuizSummaryView`.
/// - `.new` (new cards) → a `LearningSession` (3-consecutive-correct graduation),
///   ending in a graduation completion screen.
struct NameFeatureQuizView: View {
    /// Which pile this instance drives.
    enum Source {
        case pending(category: CardCategory)
        case new(newCards: [ReviewCard], category: CardCategory)
    }

    @Environment(CardStoreProvider.self) private var cardStoreProvider
    @Environment(ProgressStatsStore.self) private var progressStatsStore: ProgressStatsStore?
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let source: Source

    /// The map-pin "Name that place" mode, so it reads/writes the `nameFeature` store.
    private var cardStore: CardStore {
        cardStoreProvider.store(for: .nameFeature)
    }

    @State private var pending: TextQuizSession?
    @State private var learning: LearningSession?
    @State private var features: [any MappableFeature] = []
    @State private var inputText = ""
    @State private var hasBuilt = false
    @FocusState private var fieldFocused: Bool

    /// Completion-icon point size that scales with Dynamic Type (relative to largeTitle).
    @ScaledMetric(relativeTo: .largeTitle) private var completionIconSize: CGFloat = 64

    var body: some View {
        content
            .navigationTitle(L10n["name_feature.nav"])
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n["capital_quiz.exit"]) { dismiss() }
                }
            }
            .onAppear(perform: buildIfNeeded)
    }

    // MARK: - Content routing

    @ViewBuilder
    private var content: some View {
        switch source {
        case .pending:
            pendingContent
        case .new:
            newContent
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
            } else if let feature = currentPendingFeature(session) {
                quizBody(
                    feature: feature,
                    answerState: session.answerState,
                    progressText: "\(session.reviewedCount + 1) / \(session.questions.count)",
                    onCheck: { session.checkAnswer($0) },
                    onNext: { advancePending(session) }
                )
            } else {
                nothingDue
            }
        } else {
            nothingDue
        }
    }

    private func currentPendingFeature(_ session: TextQuizSession) -> (any MappableFeature)? {
        guard let card = session.current?.card else { return nil }
        return features.first { $0.id == card.factID }
    }

    private func advancePending(_ session: TextQuizSession) {
        session.advance()
        cardStore.persistCardChanges()
        progressStatsStore?.recordSnapshot(
            allCards: cardStoreProvider.allCards,
            modeCards: cardStore.allCards,
            mode: .nameFeature,
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
            } else if let card = session.current, let feature = features.first(where: { $0.id == card.factID }) {
                let q = nameQuestion(for: card)
                quizBody(
                    feature: feature,
                    answerState: localAnswerState,
                    progressText: String(
                        format: L10n["learn.graduated_count"],
                        session.graduatedCount, session.totalNewCards
                    ),
                    correctAnswerOverride: q?.correctAnswer,
                    onCheck: { checkLearning($0, question: q, session: session) },
                    onNext: { advanceLearning(session) }
                )
            } else {
                noNewCards
            }
        } else {
            noNewCards
        }
    }

    // The new pile drives `LearningSession` for graduation; this view owns the
    // per-question answer state (the session only records correct/wrong).
    @State private var localAnswerState: TextAnswerState = .unanswered
    @State private var lastWasCorrect = false

    private func checkLearning(_ input: String, question: TextQuestion?, session _: LearningSession) {
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
        if lastWasCorrect {
            session.recordCorrect()
        } else {
            session.recordWrong()
        }
        cardStore.persistCardChanges()
        progressStatsStore?.recordSnapshot(
            allCards: cardStoreProvider.allCards,
            modeCards: cardStore.allCards,
            mode: .nameFeature,
            streak: StreakTracker.currentStreak(language: cardStore.language)
        )
        localAnswerState = .unanswered
        inputText = ""
        fieldFocused = true
    }

    private func nameQuestion(for card: ReviewCard) -> TextQuestion? {
        TextQuizSession.nameFeatureQuestions(
            cards: [card], features: features, locale: languageManager.current
        ).first
    }

    // MARK: - Shared quiz body (map + input)

    private func quizBody(
        feature: any MappableFeature,
        answerState: TextAnswerState,
        progressText: String,
        correctAnswerOverride: String? = nil,
        onCheck: @escaping (String) -> Void,
        onNext: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            featureMap(feature: feature, revealed: answerState != .unanswered)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 16) {
                HStack {
                    Text(L10n["name_feature.prompt"])
                        .font(.headline)
                    Spacer()
                    Text(progressText)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n["name_feature.prompt"])
                .accessibilityValue(progressText)
                answerSection(
                    answerState: answerState,
                    correctAnswerOverride: correctAnswerOverride,
                    onCheck: onCheck,
                    onNext: onNext
                )
            }
            .padding()
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func featureMap(feature: any MappableFeature, revealed: Bool) -> some View {
        let region = QuizRegionMath.region(
            fittingPins: [(feature.quizLat, feature.quizLon)]
        )
        // Reveal the name on the pin only after the answer is submitted.
        let pinState: MapFeaturePinView.State = revealed ? .correctRevealed : .neutral
        return Map(initialPosition: .region(region)) {
            Annotation("", coordinate: feature.pinCoordinate) {
                MapFeaturePinView(
                    state: pinState,
                    name: feature.localizedName(for: languageManager.current)
                )
            }
            // Only this feature's overlay (river line / sea or mountain polygon).
            featureOverlays(for: [feature], answerState: revealed ? .correct(id: feature.id) : .unanswered)
        }
        .mapStyle(.imagery(elevation: .flat))
        .ignoresSafeArea(edges: .horizontal)
        .disabled(true) // a single-pin reference map; no tap interaction
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
            VStack(spacing: 12) {
                TextField(L10n["capital_quiz.placeholder"], text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                    .onSubmit { onCheck(inputText) }
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .neverAutocapitalize()
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
        VStack(spacing: 12) {
            Text(text)
                .font(.headline).foregroundStyle(color)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
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

    private var nothingDue: some View {
        ContentUnavailableView(
            L10n["name_feature.nothing_due_title"],
            systemImage: "checkmark.circle",
            description: Text(L10n["name_feature.nothing_due_desc"])
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
        switch source {
        case let .pending(category):
            features = MapFeatureCatalog.features(for: category)
            let due = cardStore.dueCards(for: category)
            let questions = TextQuizSession.nameFeatureQuestions(
                cards: due, features: features, locale: languageManager.current
            )
            pending = questions.isEmpty ? nil : TextQuizSession(questions: questions)
        case let .new(newCards, category):
            features = MapFeatureCatalog.features(for: category)
            // The active set is per-language AND per-mode; scope it to the active language and this
            // view's mode (Name That Place).
            let store: ActiveSetStore? = UserDefaultsActiveSetStore(language: cardStore.language, mode: .nameFeature)
            learning = LearningSession(newCards: newCards, category: category, store: store)
        }
    }
}

#Preview {
    NavigationStack {
        NameFeatureQuizView(source: .pending(category: .country))
            .withPreviewStore()
            .environment(LanguageManager.shared)
    }
}
