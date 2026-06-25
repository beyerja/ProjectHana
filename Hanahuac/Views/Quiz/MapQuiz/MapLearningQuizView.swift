import MapKit
import SwiftUI

/// Map-based learning view for new cards in any category.
/// Drives `MapLearningSession` (3-consecutive-correct graduation mechanic).
struct MapLearningQuizView: View {
    @Environment(CardStoreProvider.self) private var cardStoreProvider
    @Environment(LanguageManager.self) private var languageManager

    /// The Map Tab Quiz "learn new cards" flow, so it persists into the `mapQuiz` store.
    private var cardStore: CardStore {
        cardStoreProvider.store(for: .mapQuiz)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let newCards: [ReviewCard]
    /// Category used for persisting the active set and resolving features.
    /// Pass `nil` only in tests / previews.
    let category: CardCategory?

    @State private var session: MapLearningSession?
    @State private var position: MapCameraPosition = .automatic
    @State private var isAdvancing = false
    @State private var isPinching = false

    var body: some View {
        Group {
            if let session {
                if session.isFinished {
                    completionView(session: session)
                } else {
                    quizBody(session: session)
                }
            } else {
                emptyState
            }
        }
        .navigationTitle(L10n["learn_map.title"])
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n["map_quiz.exit"]) { dismiss() }
            }
        }
        .onAppear { buildSession() }
    }

    // MARK: - Quiz body

    @ViewBuilder
    private func quizBody(session: MapLearningSession) -> some View {
        // Capture answerState here (in the @ViewBuilder body) so SwiftUI's @Observable
        // tracking registers a dependency. Reading it inside the Map content builder
        // closure does not register observation and the overlays would never update.
        let answerState = session.answerState
        ZStack(alignment: .bottom) {
            Map(position: $position, bounds: QuizRegionMath.cameraBounds(for: session.mapRegion)) {
                ForEach(session.annotationFeatures, id: \.id) { feature in
                    let state = mapPinState(featureID: feature.id, answerState: answerState)
                    Annotation("", coordinate: feature.pinCoordinate) {
                        Button {
                            guard !isAdvancing, !isPinching else { return }
                            session.handleTap(featureID: feature.id)
                        } label: {
                            MapFeaturePinView(state: state, name: feature.localizedName(for: languageManager.current))
                        }
                        .disabled(answerState != .unanswered || isAdvancing || isPinching)
                        .accessibilityHint(answerState == .unanswered ? L10n["a11y.map.pin.hint"] : "")
                    }
                }
                featureOverlays(for: session.annotationFeatures, answerState: answerState)
            }
            .mapStyle(.imagery(elevation: .flat))
            .ignoresSafeArea(edges: .horizontal)
            .accessibilityIdentifier("map.tapCountry")
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { _ in isPinching = true }
                    .onEnded { _ in isPinching = false }
            )

            VStack(spacing: 0) {
                promptBanner(session: session)
                    .frame(maxWidth: .infinity)
                Spacer()
                if answerState != .unanswered {
                    feedbackBanner(session: session)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: session.answerState) { _, newState in
            guard newState != .unanswered, !isAdvancing else { return }
            isAdvancing = true
            let delay: UInt64 = {
                if case .correct = newState { return 1_500_000_000 }
                return 2_000_000_000
            }()
            Task {
                try? await Task.sleep(nanoseconds: delay)
                if case .correct = newState {
                    session.recordCorrect()
                } else {
                    session.recordWrong()
                }
                cardStore.persistCardChanges()
                if !session.isFinished {
                    withAnimation { position = .region(session.mapRegion) }
                }
                isAdvancing = false
            }
        }
        .onChange(of: session.currentIndex) { _, _ in
            position = .region(session.mapRegion)
        }
        // Reset isPinching if the app is backgrounded or interrupted mid-pinch,
        // because MagnificationGesture.onEnded does not fire on cancellation.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { isPinching = false }
        }
    }

    // MARK: - Prompt

    private func promptBanner(session: MapLearningSession) -> some View {
        let featureName = session.currentFeature?.localizedName(for: languageManager.current) ?? ""
        let graduatedText = String(
            format: L10n["learn.graduated_count"],
            session.graduatedCount,
            session.totalNewCards
        )
        return VStack(spacing: 4) {
            Text(L10n["map_quiz.tap_on_map"])
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(featureName)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            // Let the two progress pills reflow vertically at large Dynamic Type sizes instead
            // of clipping; HStack keeps them side-by-side at default sizes.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    graduatedLabel(graduatedText)
                    streakLabel(session: session)
                }
                VStack(spacing: 4) {
                    graduatedLabel(graduatedText)
                    streakLabel(session: session)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.top, 8)
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(L10n["a11y.map.prompt.label"]): \(featureName)")
        .accessibilityValue(learningProgressValue(session: session, graduatedText: graduatedText))
    }

    private func graduatedLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func streakLabel(session: MapLearningSession) -> some View {
        if let card = session.current {
            Text(String(format: L10n["learn_map.streak"], card.consecutiveCorrect))
                .font(.caption.bold())
                .foregroundStyle(Theme.Palette.new)
        }
    }

    /// Combined spoken progress: graduated count plus the current card's streak, so the learning
    /// progress is conveyed without relying on the coloured streak pill alone.
    private func learningProgressValue(session: MapLearningSession, graduatedText: String) -> String {
        guard let card = session.current else {
            return graduatedText
        }
        let streak = String(format: L10n["a11y.map.streak"], card.consecutiveCorrect)
        return "\(graduatedText), \(streak)"
    }

    // MARK: - Feedback

    @ViewBuilder
    private func feedbackBanner(session: MapLearningSession) -> some View {
        let (text, color): (String, Color) = {
            switch session.answerState {
            case .correct:
                return (L10n["map_quiz.feedback.correct"], Theme.Palette.correct)
            case let .incorrect(tappedID, _):
                let name = session.allFeatures.first { $0.id == tappedID }?
                    .localizedName(for: languageManager.current) ?? tappedID
                return ("\(L10n["map_quiz.feedback.incorrect_prefix"]) \(name)", Theme.Palette.wrong)
            case .unanswered:
                return ("", .clear)
            }
        }()
        Text(text)
            .font(.headline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(color, in: RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 24)
            .padding(.horizontal)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(feedbackAccessibilityLabel(session: session))
    }

    /// Announces the result (correct / incorrect) and the correct feature name, so the outcome is
    /// not conveyed by banner colour alone.
    private func feedbackAccessibilityLabel(session: MapLearningSession) -> String {
        switch session.answerState {
        case .correct:
            let name = session.currentFeature?.localizedName(for: languageManager.current) ?? ""
            return "\(L10n["a11y.feedback.correct"]). \(name)"
        case let .incorrect(_, correctID):
            let name = session.allFeatures.first { $0.id == correctID }?
                .localizedName(for: languageManager.current) ?? correctID
            return "\(L10n["a11y.feedback.incorrect"]). \(name)"
        case .unanswered:
            return ""
        }
    }

    // MARK: - Completion

    private func completionView(session: MapLearningSession) -> some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.Palette.accent)
                Text(L10n["learn.complete_title"])
                    .font(.title.bold())
                Text(L10n["learn.complete_desc"])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(L10n["learn.cards_graduated"])
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                Text("\(session.graduatedCount)")
                    .bold()
                    .fixedSize()
            }
            .padding()
            .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            Button(L10n["learn.done"]) { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .navigationTitle(L10n["learn.results"])
        .inlineNavigationTitle()
        .navigationBarBackButtonHidden()
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView(
            L10n["learn.no_cards_title"],
            systemImage: "checkmark.circle",
            description: Text(L10n["learn.no_cards_desc"])
        )
    }

    // MARK: - Helpers

    private func buildSession() {
        guard !newCards.isEmpty else {
            session = MapLearningSession(newCards: [], allFeatures: [], category: nil, store: nil)
            return
        }
        let features = MapFeatureCatalog.features(for: category ?? .country)
        // The active set is per-language AND per-mode; scope it to the active language and this view's
        // mode (Map Tab Quiz).
        let language = LanguageManager.shared.current.rawValue
        let store: ActiveSetStore? = category != nil
            ? UserDefaultsActiveSetStore(language: language, mode: .mapQuiz)
            : nil
        session = MapLearningSession(
            newCards: newCards,
            allFeatures: features,
            category: category,
            store: store
        )
        if let s = session { position = .region(s.mapRegion) }
    }
}

#Preview {
    NavigationStack {
        MapLearningQuizView(newCards: [], category: nil)
            .withPreviewStore()
            .environment(LanguageManager.shared)
    }
}
