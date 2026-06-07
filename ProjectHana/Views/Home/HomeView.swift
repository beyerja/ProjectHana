import SwiftUI

struct HomeView: View {
    @Environment(CardStore.self) private var cardStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    dueCountSection
                    categorySection
                    progressSection
                }
                .padding()
            }
            .navigationTitle("ProjectHana")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: – Due count

    private var dueCountSection: some View {
        VStack(spacing: 8) {
            Text("\(cardStore.dueCards().count)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text("Due today")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: – Category buttons

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study by Category")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                categoryButton(title: "Countries", icon: "globe", color: .blue, category: .country)
                categoryButton(title: "Rivers", icon: "water.waves", color: .cyan, category: .river)
                categoryButton(title: "Mountains", icon: "mountain.2", color: .brown, category: .mountain)
                categoryButton(title: "Seas", icon: "drop.fill", color: .teal, category: .sea)
            }

            NavigationLink {
                MapQuizView(category: .country)
            } label: {
                Label("All Categories", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private func categoryButton(title: String, icon: String, color: Color, category: CardCategory) -> some View {
        let due = cardStore.dueCards(for: category).count
        NavigationLink {
            quizDestination(for: category)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline).bold()
                Text("\(due) due")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private func quizDestination(for category: CardCategory) -> some View {
        switch category {
        case .country:
            QuizModePickerView()
        case .river, .mountain, .sea:
            MultipleChoiceQuizView(category: category)
        }
    }

    // MARK: – Progress link

    private var progressSection: some View {
        NavigationLink {
            ProgressPlaceholderView()
        } label: {
            Label("View Progress", systemImage: "chart.bar.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    HomeView()
        .withPreviewStore()
}
