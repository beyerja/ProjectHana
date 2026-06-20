import Foundation
import SwiftData

/// A compact, read-only snapshot of one language's progress, used by the Stats screen's
/// per-language breakdown/comparison. Computing a summary never mutates or re-seeds any language's
/// progress — it only reads.
struct LanguageProgressSummary: Identifiable {
    let locale: AppLocale
    let reviewed: Int // cards with at least one rep
    let reviewTier: Int // cards classified at the `.review` tier
    let mastered: Int // cards classified at the `.mastered` tier
    let due: Int // graduated cards whose nextReviewDate has passed
    let streak: Int // the language's day streak

    var id: String {
        locale.rawValue
    }

    /// Total cards that carry any progress (reps > 0) — a quick "is this track started?" signal.
    var hasProgress: Bool {
        reviewed > 0 || streak > 0
    }

    /// Builds a summary for `locale` by reading the language's `ReviewCard`s from `context` and its
    /// streak from `defaults`. Purely read-only.
    static func make(
        for locale: AppLocale,
        context: ModelContext,
        defaults: UserDefaults = .standard,
        now: Date = .now
    ) -> LanguageProgressSummary {
        let language = locale.rawValue
        let cards = ((try? context.fetch(FetchDescriptor<ReviewCard>())) ?? [])
            .filter { $0.language == language }

        var reviewed = 0
        var reviewTier = 0
        var mastered = 0
        var due = 0
        for card in cards {
            if card.repetitionCount > 0 { reviewed += 1 }
            switch MasteryTier.classify(card) {
            case .review: reviewTier += 1
            case .mastered: mastered += 1
            case .new, .learning: break
            }
            if card.hasGraduated, card.nextReviewDate <= now { due += 1 }
        }

        return LanguageProgressSummary(
            locale: locale,
            reviewed: reviewed,
            reviewTier: reviewTier,
            mastered: mastered,
            due: due,
            streak: StreakTracker.currentStreak(language: language, defaults: defaults)
        )
    }

    /// Summaries for every `AppLocale`, in `AppLocale.allCases` order. Languages with no progress
    /// yield zeroed summaries (consistent with the "fresh start" semantics).
    static func all(
        context: ModelContext,
        defaults: UserDefaults = .standard,
        now: Date = .now
    ) -> [LanguageProgressSummary] {
        AppLocale.allCases.map { make(for: $0, context: context, defaults: defaults, now: now) }
    }
}
