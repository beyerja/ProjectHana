import Foundation
import SwiftData

/// A compact, read-only snapshot of one quiz mode's progress within the active language, used by the
/// Stats screen's per-mode breakdown. Computing a summary never mutates or re-seeds any progress — it
/// only reads. Mirrors `LanguageProgressSummary`, but the fixed dimension is `quizMode` (scoped to a
/// single language) instead of `language`.
struct ModeProgressSummary: Identifiable {
    let mode: QuizModeID
    let reviewed: Int // cards with at least one rep
    let reviewTier: Int // cards classified at the `.review` tier
    let mastered: Int // cards classified at the `.mastered` tier
    let due: Int // graduated cards whose nextReviewDate has passed

    var id: String {
        mode.rawValue
    }

    /// Builds a summary for `(language, mode)` by reading that mode's `ReviewCard`s from `context`.
    /// Purely read-only. A mode that serves no cards for the language (or a category — e.g. typeCapital
    /// only serves Countries) simply yields lower/zeroed counts.
    static func make(
        for mode: QuizModeID,
        language: String,
        context: ModelContext,
        now: Date = .now
    ) -> ModeProgressSummary {
        let modeRaw = mode.rawValue
        let cards = ((try? context.fetch(FetchDescriptor<ReviewCard>())) ?? [])
            .filter { $0.language == language && $0.quizMode == modeRaw }

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

        return ModeProgressSummary(
            mode: mode,
            reviewed: reviewed,
            reviewTier: reviewTier,
            mastered: mastered,
            due: due
        )
    }

    /// Summaries for every `QuizModeID` in display order, scoped to `language`. Modes with no cards
    /// yield zeroed summaries.
    static func all(
        language: String,
        context: ModelContext,
        now: Date = .now
    ) -> [ModeProgressSummary] {
        QuizModeID.allCases.map { make(for: $0, language: language, context: context, now: now) }
    }
}
