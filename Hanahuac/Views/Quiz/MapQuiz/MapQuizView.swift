import MapKit
import SwiftUI

struct MapQuizView: View {
    @Environment(CardStoreProvider.self) private var cardStoreProvider
    @Environment(ProgressStatsStore.self) private var progressStatsStore: ProgressStatsStore?

    /// This view quizzes the Map Tab Quiz pending pile, so it reads/writes the `mapQuiz` store.
    private var cardStore: CardStore {
        cardStoreProvider.store(for: .mapQuiz)
    }

    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let category: CardCategory?

    @State private var session: MapQuizSession?
    // Must NOT use .automatic: MapKit resolves .automatic by framing the union of ALL map content
    // (annotations + featureOverlays). River polylines span 25–30° of latitude; large sea/mountain
    // polygons can be continent-sized. Using .automatic as the initial value causes the first
    // rendered frame to zoom out to a continental/global scale before buildSession() can apply the
    // correct .region(...). We initialise to a zero-span region (not .automatic) so MapKit has no
    // content-union framing to perform; buildSession() then immediately sets the real region before
    // the Map view is first composed (session is nil until buildSession runs, so the Map only enters
    // the view hierarchy after position has already been set to .region(s.mapRegion)).
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion())
    @State private var isAdvancing = false
    @State private var isPinching = false
    /// Owned handle for the auto-advance Task so it can be cancelled when the view is torn down
    /// (system back chevron / swipe-back). Prevents the dismiss-while-advancing crash (AC2).
    @State private var advanceTask: Task<Void, Never>?

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
                emptyState
            }
        }
        .navigationTitle(L10n["map_quiz.title"])
        .inlineNavigationTitle()
        .onAppear { buildSession() }
        .onDisappear {
            // Cancel the in-flight advance so its post-sleep persist/snapshot never runs against a
            // torn-down environment when the user exits via the system back chevron (AC2).
            advanceTask?.cancel()
            advanceTask = nil
            isAdvancing = false
        }
    }

    // MARK: – Quiz body

    @ViewBuilder
    private func quizBody(session: MapQuizSession) -> some View {
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
                if session.answerState != .unanswered {
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
            advanceTask = Task {
                let didRun = await QuizAdvanceScheduler.run(afterNanoseconds: delay) {
                    session.advance()
                    cardStore.persistCardChanges()
                    progressStatsStore?.recordSnapshot(
                        allCards: cardStoreProvider.allCards,
                        modeCards: cardStore.allCards,
                        mode: .mapQuiz,
                        streak: StreakTracker.currentStreak(language: cardStore.language)
                    )
                }
                // Only mutate map/advance state if the advance ran (i.e. the exit did not cancel us).
                if didRun {
                    if !session.isFinished {
                        withAnimation { position = .region(session.mapRegion) }
                    }
                    isAdvancing = false
                }
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

    // MARK: – Prompt

    private func promptBanner(session: MapQuizSession) -> some View {
        let featureName = session.currentFeature?.localizedName(for: languageManager.current) ?? ""
        return VStack(spacing: 4) {
            Text(L10n["map_quiz.tap_on_map"])
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(featureName)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("\(min(session.correctCount + 1, session.totalCards)) / \(session.totalCards)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
        )
        .padding(.top, 8)
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(L10n["a11y.map.prompt.label"]): \(featureName)")
        .accessibilityValue(
            String(
                format: L10n["a11y.map.progress"],
                min(session.correctCount + 1, session.totalCards),
                session.totalCards
            )
        )
    }

    // MARK: – Feedback

    @ViewBuilder
    private func feedbackBanner(session: MapQuizSession) -> some View {
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
            .background(color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            // Clear MapKit's auto-rendered "Apple Maps / Legal" attribution, which sits at the map's
            // bottom-left edge: extra bottom inset keeps the feedback banner from overlapping it.
            .padding(.bottom, 40)
            .padding(.horizontal)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(feedbackAccessibilityLabel(session: session))
    }

    /// Announces the result (correct / incorrect) and the correct feature name, so the outcome is
    /// not conveyed by banner colour alone.
    private func feedbackAccessibilityLabel(session: MapQuizSession) -> String {
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

    // MARK: – Empty state

    private var emptyState: some View {
        ContentUnavailableView(
            L10n["map_quiz.nothing_due_title"],
            systemImage: "checkmark.circle",
            description: Text(L10n["map_quiz.nothing_due_desc"])
        )
    }

    // MARK: – Helpers

    private func buildSession() {
        let cat = category ?? .country
        let due = cardStore.dueCards(for: cat)
            .filter { cardStore.allCards.map(\.factID).contains($0.factID) }
        guard !due.isEmpty else { session = MapQuizSession(cards: [], allFeatures: [])
            return
        }
        session = MapQuizSession(cards: due, allFeatures: MapFeatureCatalog.features(for: cat))
        if let s = session { position = .region(s.mapRegion) }
    }
}

#Preview {
    NavigationStack {
        MapQuizView(category: .country)
            .withPreviewStore()
    }
}
