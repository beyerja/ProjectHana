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

    private let borders = CountryBorderLoader.shared

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
            Text(session.currentCountry?.localizedName(for: languageManager.current) ?? "")
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
                return (L10n["map_quiz.feedback.correct"], .green)
            case .incorrect(let tappedID, _):
                let name = session.allCountries.first { $0.id == tappedID }?.localizedName(for: languageManager.current) ?? tappedID
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
        let due = cardStore.dueCards(for: category ?? .country)
            .filter { cardStore.allCards.map(\.factID).contains($0.factID) }
        guard !due.isEmpty else { session = MapQuizSession(cards: [], allCountries: []); return }
        let geoData = GeographyDataLoader.shared
        session = MapQuizSession(cards: due, allCountries: geoData.countries)
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

// MARK: – Pin view

struct CountryPinView: View {
    enum State { case neutral, correct, incorrectTapped, correctRevealed }

    let state: State
    let name: String

    private var color: Color {
        switch state {
        case .neutral:          return .blue
        case .correct:          return .green
        case .incorrectTapped:  return .red
        case .correctRevealed:  return .green
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(radius: 2)
            if state == .correctRevealed || state == .correct {
                Text(name)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color, in: Capsule())
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}

#Preview {
    NavigationStack {
        MapQuizView(category: .country)
            .withPreviewStore()
    }
}
