import SwiftUI

struct CategoryDetailView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(LanguageManager.self) private var lang

    let category: CardCategory

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                tilePair
                progressLink
            }
            .padding()
        }
        .navigationTitle(category.displayName)
        .inlineNavigationTitle()
    }

    // MARK: – Tiles

    private var tilePair: some View {
        HStack(spacing: 16) {
            newTile
            pendingTile
        }
    }

    private var newTile: some View {
        let cards = cardStore.newCards(for: category)
        return NavigationLink {
            newDestination(cards: cards)
        } label: {
            tileLabel(
                title: L10n["home.tile.new"],
                count: cards.count,
                icon: "plus.circle.fill",
                color: .orange,
                enabled: !cards.isEmpty
            )
        }
        .disabled(cards.isEmpty)
    }

    @ViewBuilder
    private func newDestination(cards: [ReviewCard]) -> some View {
        switch category {
        case .country:
            LearningModePickerView()
        case .river, .mountain, .sea:
            LearningQuizView(newCards: cards, category: category)
        }
    }

    private var pendingTile: some View {
        let count = cardStore.dueCards(for: category).count
        return NavigationLink {
            pendingDestination
        } label: {
            tileLabel(
                title: L10n["home.tile.pending"],
                count: count,
                icon: "clock.fill",
                color: .blue,
                enabled: count > 0
            )
        }
        .disabled(count == 0)
    }

    @ViewBuilder
    private var pendingDestination: some View {
        switch category {
        case .country:
            QuizModePickerView()
        case .river, .mountain, .sea:
            MultipleChoiceQuizView(category: category)
        }
    }

    private func tileLabel(title: String, count: Int, icon: String, color: Color, enabled: Bool) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(enabled ? color : .secondary)
            Text("\(count)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(enabled ? color : .secondary)
            Text(title)
                .font(.subheadline).bold()
                .foregroundStyle(enabled ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            enabled ? color.opacity(0.12) : Color(.systemGray6),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    // MARK: – Progress link

    private var progressLink: some View {
        NavigationLink {
            StatsView()
        } label: {
            Label(L10n["home.view_progress"], systemImage: "chart.bar.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(category: .country)
            .withPreviewStore()
    }
}
