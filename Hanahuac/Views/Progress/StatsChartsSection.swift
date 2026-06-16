import Charts
import SwiftUI

/// Time window for the trend charts.
enum StatsRange: CaseIterable, Identifiable {
    case week
    case month
    case all

    var id: Self {
        self
    }

    /// Number of days back from today, or nil for all-time.
    var days: Int? {
        switch self {
        case .week: 7
        case .month: 30
        case .all: nil
        }
    }

    var label: String {
        switch self {
        case .week: L10n["stats.charts.range.7d"]
        case .month: L10n["stats.charts.range.30d"]
        case .all: L10n["stats.charts.range.all"]
        }
    }
}

/// One charted day, projected from a `DailyProgressSnapshot` for the currently-selected category.
private struct DailyPoint: Identifiable {
    let id = UUID()
    let day: Date
    let review: Int
    let mastered: Int
    let reviewsCompleted: Int
    let cardsGraduated: Int
    let streak: Int
}

/// The "Trends Over Time" charts shown below the snapshot cards in `StatsView`. Renders the
/// accumulated `DailyProgressSnapshot` history with Swift Charts, filtered by a time range and an
/// optional category.
struct StatsChartsSection: View {
    /// All snapshots, oldest-first (as returned by `ProgressStatsStore.allSnapshots`).
    let snapshots: [DailyProgressSnapshot]

    @State private var range: StatsRange = .week
    @State private var categoryFilter: CardCategory?

    private var points: [DailyPoint] {
        let cutoff: Date? = range.days.flatMap {
            Calendar.current.date(byAdding: .day, value: -($0 - 1), to: Calendar.current.startOfDay(for: .now))
        }
        return snapshots
            .filter { snap in cutoff.map { snap.day >= $0 } ?? true }
            .map { snap in
                DailyPoint(
                    day: snap.day,
                    review: snap.reviewCount(for: categoryFilter),
                    mastered: snap.masteredCount(for: categoryFilter),
                    reviewsCompleted: snap.reviewsCompleted,
                    cardsGraduated: snap.cardsGraduated,
                    streak: snap.streak
                )
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n["stats.charts.title"])
                .font(.headline)
                .foregroundStyle(.secondary)

            controls

            if points.count < 2 {
                emptyState
            } else {
                masteryGrowthChart
                reviewsCompletedChart
                cardsGraduatedChart
                streakChart
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 10) {
            Picker(L10n["stats.charts.title"], selection: $range) {
                ForEach(StatsRange.allCases) { r in
                    Text(r.label).tag(r)
                }
            }
            .pickerStyle(.segmented)

            Picker(L10n["stats.by_category"], selection: $categoryFilter) {
                Text(L10n["stats.charts.category.all"]).tag(CardCategory?.none)
                ForEach(CardCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(CardCategory?.some(category))
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var emptyState: some View {
        Text(L10n["stats.charts.empty"])
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Theme.Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Charts

    private func chartCard(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            content()
                .frame(height: 160)
        }
        .padding(12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var masteryGrowthChart: some View {
        chartCard(L10n["stats.charts.mastery_growth"]) {
            Chart(points) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value(L10n["stats.charts.series.review"], point.review)
                )
                .foregroundStyle(by: .value("Series", L10n["stats.charts.series.review"]))

                LineMark(
                    x: .value("Day", point.day),
                    y: .value(L10n["stats.charts.series.mastered"], point.mastered)
                )
                .foregroundStyle(by: .value("Series", L10n["stats.charts.series.mastered"]))
            }
            .chartForegroundStyleScale([
                L10n["stats.charts.series.review"]: MasteryTier.review.color,
                L10n["stats.charts.series.mastered"]: MasteryTier.mastered.color
            ])
        }
    }

    private var reviewsCompletedChart: some View {
        chartCard(L10n["stats.charts.reviews_completed"]) {
            Chart(points) { point in
                BarMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value(L10n["stats.charts.reviews_completed"], point.reviewsCompleted)
                )
                .foregroundStyle(Theme.Palette.accent)
            }
        }
    }

    private var cardsGraduatedChart: some View {
        chartCard(L10n["stats.charts.cards_graduated"]) {
            Chart(points) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value(L10n["stats.charts.cards_graduated"], point.cardsGraduated)
                )
                .foregroundStyle(Theme.Palette.sage)
                AreaMark(
                    x: .value("Day", point.day),
                    y: .value(L10n["stats.charts.cards_graduated"], point.cardsGraduated)
                )
                .foregroundStyle(Theme.Palette.sage.opacity(0.15))
            }
        }
    }

    private var streakChart: some View {
        chartCard(L10n["stats.charts.streak_history"]) {
            Chart(points) { point in
                BarMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value(L10n["stats.charts.streak_history"], point.streak)
                )
                .foregroundStyle(Theme.Palette.correct)
            }
        }
    }
}

#if DEBUG
    extension DailyProgressSnapshot {
        /// Deterministic sample history for previews and the in-memory preview store.
        static func sampleHistory(days: Int = 14) -> [DailyProgressSnapshot] {
            let cal = Calendar.current
            let today = cal.startOfDay(for: .now)
            return (0 ..< days).compactMap { offset -> DailyProgressSnapshot? in
                guard let day = cal.date(byAdding: .day, value: -(days - 1 - offset), to: today) else { return nil }
                let grown = offset + 1
                return DailyProgressSnapshot(
                    day: day,
                    reviewsCompleted: 3 + offset % 5,
                    cardsGraduated: grown,
                    streak: grown,
                    reviewCount: max(0, grown - offset / 3),
                    masteredCount: offset / 2,
                    countryReview: max(0, grown - offset / 3),
                    countryMastered: offset / 2
                )
            }
        }
    }

    #Preview {
        ScrollView {
            StatsChartsSection(snapshots: DailyProgressSnapshot.sampleHistory())
                .padding()
                .environment(LanguageManager.shared)
        }
        .background(Theme.Palette.canvas)
    }
#endif
