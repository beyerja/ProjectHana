import SwiftUI

struct StatsView: View {
    @Environment(CardStoreProvider.self) private var cardStoreProvider
    @Environment(ProgressStatsStore.self) private var progressStatsStore: ProgressStatsStore?
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var modelContext
    @State private var streak: Int = 0 // resolved from the active language in onAppear
    @State private var showLanguageBreakdown = false
    @State private var showModeBreakdown = false

    /// The default Progress view is mode-aggregated: it sums each fact's progress across all quiz
    /// modes (per-mode breakdown is added in a later story). `allCards`/`dueCards` come from the
    /// provider's union over the per-mode stores.
    private var all: [ReviewCard] {
        cardStoreProvider.allCards
    }

    private var dueCount: Int {
        cardStoreProvider.dueCards().count
    }

    private var reviewedCount: Int {
        all.filter { $0.repetitionCount > 0 }.count
    }

    var body: some View {
        // Read both stores' mutation signals so SwiftUI Observation ties this view's invalidation to
        // their writes; the fetch-derived computed properties below read no @Observable stored property
        // and would otherwise never refresh after a quiz mutates cards or records a snapshot.
        _ = cardStoreProvider.revision
        _ = progressStatsStore?.revision
        return ScrollView {
            VStack(spacing: 28) {
                activeLanguageHeader
                summarySection
                categoryBreakdownSection
                if let progressStatsStore {
                    StatsChartsSection(snapshots: progressStatsStore.allSnapshots)
                }
                modeBreakdownSection
                languageBreakdownSection
                tierLegendSection
            }
            .padding()
        }
        .background(Theme.Palette.canvas.ignoresSafeArea())
        .navigationTitle(L10n["stats.title"])
        .inlineNavigationTitle()
        .onAppear { streak = StreakTracker.currentStreak(language: languageManager.current.rawValue) }
        .id(languageManager.current)
    }

    // MARK: – Active-language header

    /// Labels which language's progress the default view is showing.
    private var activeLanguageHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "globe")
                .foregroundStyle(Theme.Palette.accent)
            Text(L10n["stats.showing_language"])
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(languageManager.current.displayName)
                .font(.caption.bold())
                .foregroundStyle(.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Per-language breakdown

    private var languageBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showLanguageBreakdown.toggle() }
            } label: {
                HStack {
                    Text(L10n["stats.by_language"])
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: showLanguageBreakdown ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showLanguageBreakdown {
                VStack(spacing: 1) {
                    ForEach(LanguageProgressSummary.all(context: modelContext)) { summary in
                        languageRow(summary)
                    }
                }
                .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 14))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func languageRow(_ summary: LanguageProgressSummary) -> some View {
        let isActive = summary.locale == languageManager.current
        return HStack {
            Text(summary.locale.displayName)
                .font(.subheadline.weight(isActive ? .bold : .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
            languageMetric("\(summary.mastered)", color: Theme.Palette.correct)
            languageMetric("\(summary.reviewTier)", color: Theme.Palette.accent)
            languageMetric("\(summary.due)", color: Theme.Palette.new)
            languageMetric("\(summary.streak)", color: Theme.Palette.correct)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isActive ? Theme.Palette.accent.opacity(0.08) : Color.clear)
    }

    private func languageMetric(_ value: String, color: Color) -> some View {
        Text(value)
            .font(.subheadline.bold())
            .foregroundStyle(color)
            .frame(width: 40)
    }

    // MARK: – Per-mode breakdown

    /// Collapsed by default, so the Progress screen's default totals stay mode-aggregated. Expanding it
    /// shows each quiz mode's individual totals for the active language (mastered / review / due) —
    /// backed by `ModeProgressSummary`. `typeCapital` naturally shows only its Countries cards.
    private var modeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showModeBreakdown.toggle() }
            } label: {
                HStack {
                    Text(L10n["stats.by_mode"])
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: showModeBreakdown ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showModeBreakdown {
                VStack(spacing: 1) {
                    let summaries = ModeProgressSummary.all(
                        language: languageManager.current.rawValue,
                        context: modelContext
                    )
                    ForEach(summaries) { summary in
                        modeRow(summary)
                    }
                }
                .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 14))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func modeRow(_ summary: ModeProgressSummary) -> some View {
        HStack {
            Text(L10n[HomeQuizMode(quizModeID: summary.mode).titleKey])
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            languageMetric("\(summary.mastered)", color: Theme.Palette.correct)
            languageMetric("\(summary.reviewTier)", color: Theme.Palette.accent)
            languageMetric("\(summary.due)", color: Theme.Palette.new)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: – Summary

    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(value: "\(reviewedCount)", label: L10n["stats.cards_reviewed"], color: Theme.Palette.accent)
                statCard(value: "\(dueCount)", label: L10n["stats.due_today"], color: Theme.Palette.new)
                statCard(value: "\(streak)", label: L10n["stats.day_streak"], color: Theme.Palette.correct)
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
            Text(L10n["stats.by_category"])
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 1) {
                categoryHeader
                ForEach(CardCategory.allCases, id: \.self) { category in
                    categoryRow(category)
                }
            }
            .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var categoryHeader: some View {
        HStack {
            Text(L10n["stats.category_header"]).frame(maxWidth: .infinity, alignment: .leading)
            ForEach(MasteryTier.allCases, id: \.self) { tier in
                VStack(spacing: 2) {
                    Image(systemName: tier.icon)
                        .foregroundStyle(tier.color)
                    Text(tier.localizedName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: 40)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(tier.localizedName)
            }
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.Palette.surfaceAlt)
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
                    .frame(width: 40)
                    .accessibilityLabel("\(tier.localizedName): \(count)")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: – Tier legend

    private var tierLegendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n["stats.mastery_tiers"])
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(MasteryTier.allCases, id: \.self) { tier in
                    HStack(spacing: 10) {
                        Image(systemName: tier.icon)
                            .foregroundStyle(tier.color)
                            .frame(width: 20)
                        Text(tier.localizedName)
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
    /// Short, localized column/legend name (new / learning / review / mastered). Replaces the
    /// hardcoded English `rawValue` as user-visible and accessibility text.
    var localizedName: String {
        switch self {
        case .new: L10n["stats.tier.name.new"]
        case .learning: L10n["stats.tier.name.learning"]
        case .review: L10n["stats.tier.name.review"]
        case .mastered: L10n["stats.tier.name.mastered"]
        }
    }

    var description: String {
        switch self {
        case .new: L10n["stats.tier.not_started"]
        case .learning: L10n["stats.tier.reps_1_2"]
        case .review: L10n["stats.tier.reps_3_4"]
        case .mastered: L10n["stats.tier.mastered"]
        }
    }
}

extension CardCategory: CaseIterable {
    public static var allCases: [CardCategory] {
        [.country, .river, .mountain, .sea]
    }

    var displayName: String {
        switch self {
        case .country: L10n["home.category.countries"]
        case .river: L10n["home.category.rivers"]
        case .mountain: L10n["home.category.mountains"]
        case .sea: L10n["home.category.seas"]
        }
    }
}

#Preview {
    NavigationStack {
        StatsView()
            .withPreviewStore()
            .environment(LanguageManager.shared)
    }
}
