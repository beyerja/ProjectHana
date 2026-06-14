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
                    .foregroundStyle(accuracy >= 70 ? Theme.Palette.accent : Theme.Palette.accent)
                Text(L10n["quiz_summary.session_complete"])
                    .font(.title.bold())
            }

            VStack(spacing: 16) {
                statRow(label: L10n["quiz_summary.cards_reviewed"], value: "\(reviewed)")
                statRow(label: L10n["quiz_summary.correct"], value: "\(correct) (\(accuracy)%)")
                if let next = nextDue {
                    statRow(label: L10n["quiz_summary.next_review"], value: next.formatted(.relative(presentation: .named)))
                }
            }
            .padding()
            .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            Button(L10n["quiz_summary.done"]) { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .navigationTitle(L10n["quiz_summary.results"])
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
