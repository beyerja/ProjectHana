import SwiftUI

struct QuizSummaryView: View {
    @Environment(\.dismiss) private var dismiss

    let reviewed: Int
    let correct: Int
    let nextDue: Date?

    private var accuracy: Int {
        guard reviewed > 0 else { return 0 }
        return Int((Double(correct) / Double(reviewed)) * 100)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: accuracy >= 70 ? "star.fill" : "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(accuracy >= 70 ? .yellow : .blue)
                Text("Session Complete!")
                    .font(.title.bold())
            }

            VStack(spacing: 16) {
                statRow(label: "Cards reviewed", value: "\(reviewed)")
                statRow(label: "Correct", value: "\(correct) (\(accuracy)%)")
                if let next = nextDue {
                    statRow(label: "Next review", value: next.formatted(.relative(presentation: .named)))
                }
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

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
    }
}

#Preview {
    NavigationStack {
        QuizSummaryView(reviewed: 10, correct: 8, nextDue: Date(timeIntervalSinceNow: 86400))
    }
}
