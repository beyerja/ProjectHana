import SwiftUI
import MapKit

struct MapQuizView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let category: CardCategory?

    @State private var session: MapQuizSession?
    @State private var position: MapCameraPosition = .automatic
    @State private var isAdvancing = false
    @State private var isPinching = false

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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n["map_quiz.exit"]) { dismiss() }
            }
        }
        .onAppear { buildSession() }
    }

    // MARK: – Quiz body

    @ViewBuilder
    private func quizBody(session: MapQuizSession) -> some View {
        // Capture answerState here (in the @ViewBuilder body) so SwiftUI's @Observable
        // tracking registers a dependency. Reading it inside the Map content builder
        // closure does not register observation and the overlays would never update.
        let answerState = session.answerState
        ZStack(alignment: .bottom) {
            Map(position: $position) {
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
                    }
                }
                featureOverlays(for: session.annotationFeatures, answerState: answerState)
            }
            .mapStyle(.imagery(elevation: .flat))
            .ignoresSafeArea(edges: .horizontal)
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
            Task {
                try? await Task.sleep(nanoseconds: delay)
                session.advance()
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

    // MARK: – Prompt

    private func promptBanner(session: MapQuizSession) -> some View {
        VStack(spacing: 4) {
            Text(L10n["map_quiz.tap_on_map"])
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(session.currentFeature?.localizedName(for: languageManager.current) ?? "")
                .font(.title2.bold())
            Text("\(session.reviewedCount + 1) / \(session.cards.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.top, 8)
        .padding(.horizontal)
    }

    // MARK: – Feedback

    @ViewBuilder
    private func feedbackBanner(session: MapQuizSession) -> some View {
        let (text, color): (String, Color) = {
            switch session.answerState {
            case .correct:
                return (L10n["map_quiz.feedback.correct"], Theme.Palette.correct)
            case .incorrect(let tappedID, _):
                let name = session.allFeatures.first { $0.id == tappedID }?.localizedName(for: languageManager.current) ?? tappedID
                return ("\(L10n["map_quiz.feedback.incorrect_prefix"]) \(name)", Theme.Palette.wrong)
            case .unanswered:
                return ("", .clear)
            }
        }()
        Text(text)
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(color, in: RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 24)
            .padding(.horizontal)
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
        guard !due.isEmpty else { session = MapQuizSession(cards: [], allFeatures: []); return }
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
