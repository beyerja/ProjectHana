import SwiftUI

enum CapitalQuizMode {
    case capitalOfCountry    // "What is the capital of X?"
    case countryOfCapital    // "Which country has X as its capital?"
}

struct CapitalQuizView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(\.dismiss) private var dismiss

    let mode: CapitalQuizMode

    @State private var session: TextQuizSession?
    @State private var inputText = ""
    @FocusState private var fieldFocused: Bool

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
                ContentUnavailableView("Nothing Due", systemImage: "checkmark.circle",
                    description: Text("No cards are due right now."))
            }
        }
        .navigationTitle(mode == .capitalOfCountry ? "Capital Quiz" : "Country Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Exit") { dismiss() } }
        }
        .onAppear { buildSession() }
    }

    // MARK: – Quiz body

    private func quizBody(session: TextQuizSession) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                progressHeader(session: session)
                promptCard(session: session)
                answerSection(session: session)
                Spacer(minLength: 0)
            }
            .padding()
        }
        .onChange(of: session.currentIndex) { _, _ in
            inputText = ""
            fieldFocused = true
        }
    }

    private func progressHeader(session: TextQuizSession) -> some View {
        HStack {
            Text("\(session.reviewedCount + 1) / \(session.questions.count)")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text("\(session.correctCount) correct")
                .font(.subheadline).foregroundStyle(.green)
        }
    }

    private func promptCard(session: TextQuizSession) -> some View {
        Text(session.current?.prompt ?? "")
            .font(.title3.bold())
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func answerSection(session: TextQuizSession) -> some View {
        switch session.answerState {
        case .unanswered:
            unansweredInput(session: session)
        case .correct:
            feedbackView(text: "Correct! ✓", color: .green, session: session)
        case .incorrect(let correctAnswer):
            VStack(spacing: 12) {
                feedbackView(text: "The answer is: \(correctAnswer)", color: .red, session: session)
            }
        }
    }

    private func unansweredInput(session: TextQuizSession) -> some View {
        VStack(spacing: 16) {
            TextField("Type your answer…", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($fieldFocused)
                .onSubmit { session.checkAnswer(inputText) }
                .submitLabel(.done)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button("Check") { session.checkAnswer(inputText) }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(inputText.isEmpty ? Color.secondary.opacity(0.3) : Color.blue,
                            in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .disabled(inputText.isEmpty)
        }
        .onAppear { fieldFocused = true }
    }

    private func feedbackView(text: String, color: Color, session: TextQuizSession) -> some View {
        VStack(spacing: 16) {
            Text(text)
                .font(.headline)
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))

            Button("Next →") { session.advance() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }

    // MARK: – Helpers

    private func buildSession() {
        let due = cardStore.dueCards(for: .country)
        guard !due.isEmpty else { session = nil; return }
        let countries = GeographyDataLoader.shared.countries
        let questions = mode == .capitalOfCountry
            ? TextQuizSession.capitalQuestions(cards: due, countries: countries)
            : TextQuizSession.reverseCapitalQuestions(cards: due, countries: countries)
        session = TextQuizSession(questions: questions)
    }
}

#Preview {
    NavigationStack {
        CapitalQuizView(mode: .capitalOfCountry)
            .withPreviewStore()
    }
}
