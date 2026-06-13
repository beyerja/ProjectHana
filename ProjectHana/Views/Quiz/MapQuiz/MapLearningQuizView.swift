import SwiftUI
import MapKit

/// Map-based learning view for new country cards.
/// Drives `MapLearningSession` (3-consecutive-correct graduation mechanic).
struct MapLearningQuizView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let newCards: [ReviewCard]
    /// Category used for persisting the active set. Pass `nil` only in tests / previews.
    let category: CardCategory?

    @State private var session: MapLearningSession?
    @State private var position: MapCameraPosition = .automatic
    @State private var isAdvancing = false
    @State private var isPinching = false

    private let borders = CountryBorderLoader.shared

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
        // closure does not register observation and the polygons would never update.
        let answerState = session.answerState
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(session.annotationCountries, id: \.id) { country in
                    let state = pinState(for: country, answerState: answerState)
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: country.lat, longitude: country.lon)) {
                        Button {
                            guard !isAdvancing, !isPinching else { return }
                            session.handleTap(countryID: country.id)
                        } label: {
                            CountryPinView(state: state, name: country.localizedName(for: languageManager.current))
                        }
                        .disabled(answerState != .unanswered || isAdvancing || isPinching)
                    }
                }
                ForEach(Array(borders.keys), id: \.self) { id in
                    if let rings = borders[id] {
                        ForEach(rings.indices, id: \.self) { i in
                            MapPolygon(coordinates: rings[i])
                                .foregroundStyle(answerState.polygonFillColor(for: id))
                                .stroke(.white.opacity(0.55), lineWidth: 0.8)
                        }
                    }
                }
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
            Text(session.currentCountry?.localizedName(for: languageManager.current) ?? "")
                .font(.title2.bold())
            HStack(spacing: 12) {
                Text(String(format: L10n["learn.graduated_count"], session.graduatedCount, session.totalNewCards))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let card = session.current {
                    Text(String(format: L10n["learn_map.streak"], card.consecutiveCorrect))
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
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
                return (L10n["map_quiz.feedback.correct"], .green)
            case .incorrect(let tappedID, _):
                let geoData = GeographyDataLoader.shared
                let name = geoData.countries.first { $0.id == tappedID }?.localizedName(for: languageManager.current) ?? tappedID
                return ("\(L10n["map_quiz.feedback.incorrect_prefix"]) \(name)", .red)
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
                    .foregroundStyle(.yellow)
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
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            Button(L10n["learn.done"]) { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 14))
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
            session = MapLearningSession(newCards: [], allCountries: [], category: nil, store: nil)
            return
        }
        let geoData = GeographyDataLoader.shared
        let store: ActiveSetStore? = category != nil ? UserDefaultsActiveSetStore() : nil
        session = MapLearningSession(newCards: newCards, allCountries: geoData.countries,
                                     category: category, store: store)
        if let s = session { position = .region(s.mapRegion) }
    }

    private func pinState(for country: Country, answerState: AnswerState) -> CountryPinView.State {
        switch answerState {
        case .unanswered:
            return .neutral
        case .correct(let id):
            return country.id == id ? .correct : .neutral
        case .incorrect(let tappedID, let correctID):
            if country.id == tappedID { return .incorrectTapped }
            if country.id == correctID { return .correctRevealed }
            return .neutral
        }
    }
}

#Preview {
    NavigationStack {
        MapLearningQuizView(newCards: [], category: nil)
            .withPreviewStore()
            .environment(LanguageManager.shared)
    }
}
