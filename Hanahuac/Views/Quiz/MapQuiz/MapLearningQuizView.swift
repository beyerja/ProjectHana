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
        VStack(spacing: 4) {
            Text(L10n["map_quiz.tap_on_map"])
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(session.currentFeature?.localizedName(for: languageManager.current) ?? "")
                .font(.title2.bold())
            HStack(spacing: 12) {
                Text(String(format: L10n["learn.graduated_count"], session.graduatedCount, session.totalNewCards))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let card = session.current {
                    Text(String(format: L10n["learn_map.streak"], card.consecutiveCorrect))
                        .font(.caption.bold())
                        .foregroundStyle(Theme.Palette.new)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.top, 8)
        .padding(.horizontal)
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
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(color, in: RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 24)
            .padding(.horizontal)
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

            HStack {
                Text(L10n["learn.cards_graduated"]).foregroundStyle(.secondary)
                Spacer()
                Text("\(session.graduatedCount)").bold()
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
