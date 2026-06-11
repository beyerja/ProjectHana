import SwiftUI

struct LearningQuizView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var session: LearningSession
    @State private var currentQuestion: MCQQuestion?
    @State private var answerState: MCQAnswerState = .unanswered
    @State private var isAdvancing = false

    private let geo = GeographyDataLoader.shared

    init(newCards: [ReviewCard]) {
        _session = State(initialValue: LearningSession(newCards: newCards))
    }

    var body: some View {
        Group {
            if session.isFinished {
                completionView
            } else if let question = currentQuestion {
                quizBody(question: question)
            } else {
                ContentUnavailableView(
                    "No cards to learn",
                    systemImage: "checkmark.circle",
                    description: Text("All cards are already in your review schedule.")
                )
            }
        }
        .navigationTitle("Learn")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Exit") { dismiss() } }
        }
        .onAppear { refreshQuestion() }
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
            Text("\(session.graduatedCount) / \(session.totalNewCards) graduated")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text("\(session.activeSet.count) active")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func promptCard(question: MCQQuestion) -> some View {
        Text(question.prompt)
            .font(.title3.bold())
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func optionButtons(question: MCQQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
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
            }
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
        Task {
            try? await Task.sleep(nanoseconds: delay)
            if wasCorrect {
                session.recordCorrect()
            } else {
                session.recordWrong()
            }
            answerState = .unanswered
            isAdvancing = false
            refreshQuestion()
        }
    }

    private func refreshQuestion() {
        guard let card = session.current else { currentQuestion = nil; return }
        currentQuestion = makeQuestion(for: card)
    }

    // MARK: – Completion

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)
                Text("Learning Complete!")
                    .font(.title.bold())
                Text("All cards have been added to your review schedule.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack {
                Text("Cards graduated").foregroundStyle(.secondary)
                Spacer()
                Text("\(session.graduatedCount)").bold()
            }
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            Button("Done") { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .navigationTitle("Results")
        .inlineNavigationTitle()
        .navigationBarBackButtonHidden()
    }

    // MARK: – Button styling

    private func buttonColor(for option: MCQOption) -> Color {
        switch answerState {
        case .unanswered:
            return .blue.opacity(0.15)
        case .correct(let id):
            return option.id == id ? .green : .blue.opacity(0.1)
        case .incorrect(let chosenID, let correctID):
            if option.id == chosenID { return .red }
            if option.id == correctID { return .green }
            return .blue.opacity(0.1)
        }
    }

    private func buttonForeground(for option: MCQOption) -> Color {
        switch answerState {
        case .unanswered:
            return .blue
        case .correct(let id):
            return option.id == id ? .white : .secondary
        case .incorrect(let chosenID, let correctID):
            if option.id == chosenID || option.id == correctID { return .white }
            return .secondary
        }
    }

    // MARK: – Question factory

    private func makeQuestion(for card: ReviewCard) -> MCQQuestion? {
        switch card.cardCategory {
        case .country:
            return MultipleChoiceSession.countryCapitalQuestions(
                cards: [card], countries: geo.countries).first
        case .river:
            return MultipleChoiceSession.continentQuestions(
                cards: [card], facts: geo.rivers,
                factID: \.id, factName: \.name, factContinent: \.continent,
                categoryLabel: "river").first
        case .mountain:
            return MultipleChoiceSession.continentQuestions(
                cards: [card], facts: geo.mountains,
                factID: \.id, factName: \.name, factContinent: \.continent,
                categoryLabel: "mountain range").first
        case .sea:
            return MultipleChoiceSession.seaIdentificationQuestions(
                cards: [card], seas: geo.seas).first
        }
    }
}
