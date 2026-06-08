import SwiftUI

struct StatsView: View {
    @Environment(CardStore.self) private var cardStore
    @State private var streak: Int = StreakTracker.currentStreak()

    private var all: [ReviewCard] { cardStore.allCards }
    private var dueCount: Int { cardStore.dueCards().count }
    private var reviewedCount: Int { all.filter { $0.repetitionCount > 0 }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                summarySection
                categoryBreakdownSection
                tierLegendSection
            }
            .padding()
        }
        .navigationTitle("Progress")
        .inlineNavigationTitle()
        .onAppear { streak = StreakTracker.currentStreak() }
    }

    // MARK: – Summary

    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(value: "\(reviewedCount)", label: "Cards reviewed", color: .blue)
                statCard(value: "\(dueCount)", label: "Due today", color: .orange)
                statCard(value: "\(streak)", label: "Day streak", color: .green)
            }
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: – Per-category breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 1) {
                categoryHeader
                ForEach(CardCategory.allCases, id: \.self) { category in
                    categoryRow(category)
                }
            }
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var categoryHeader: some View {
        HStack {
            Text("Category").frame(maxWidth: .infinity, alignment: .leading)
            ForEach(MasteryTier.allCases, id: \.self) { tier in
                Image(systemName: tier.icon)
                    .foregroundStyle(tier.color)
                    .frame(width: 36)
            }
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary)
    }

    private func categoryRow(_ category: CardCategory) -> some View {
        let cards = all.filter { $0.cardCategory == category }
        let counts = MasteryTier.allCases.map { tier in
            cards.filter { MasteryTier.classify($0) == tier }.count
        }
        return HStack {
            Text(category.displayName)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(zip(MasteryTier.allCases, counts)), id: \.0) { tier, count in
                Text("\(count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(count > 0 ? tier.color : Color.secondary)
                    .frame(width: 36)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: – Tier legend

    private var tierLegendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mastery Tiers")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(MasteryTier.allCases, id: \.self) { tier in
                    HStack(spacing: 10) {
                        Image(systemName: tier.icon)
                            .foregroundStyle(tier.color)
                            .frame(width: 20)
                        Text(tier.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(tier.color)
                        Spacer()
                        Text(tier.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(tier.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

extension MasteryTier {
    var description: String {
        switch self {
        case .new:      return "Not started"
        case .learning: return "Reps 1–2"
        case .review:   return "Reps 3–4"
        case .mastered: return "Reps ≥ 5, EF ≥ 2.0"
        }
    }
}

extension CardCategory: CaseIterable {
    public static var allCases: [CardCategory] { [.country, .river, .mountain, .sea] }

    var displayName: String {
        switch self {
        case .country:  return "Countries"
        case .river:    return "Rivers"
        case .mountain: return "Mountains"
        case .sea:      return "Seas"
        }
    }
}

#Preview {
    NavigationStack {
        StatsView()
            .withPreviewStore()
    }
}
