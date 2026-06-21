import Foundation

/// Stable, persisted identifier for a quiz mode — the second progress dimension alongside `language`.
///
/// Progress is tracked independently per quiz mode, so a `ReviewCard`'s canonical identity is
/// (`factID`, `language`, `quizMode`) where `quizMode` is one of these raw values. This enum lives in
/// the Foundation-only model layer (no SwiftUI dependency) so the persistence models, `CardStore`,
/// `ActiveSetStore`, and the one-time `ProgressMigrator` can all reference the same constants. The
/// SwiftUI-facing `HomeQuizMode` maps to/from these tokens (see `HomeQuizMode.quizModeID`).
///
/// The raw values are a persisted contract: changing one would orphan existing progress rows, so they
/// are fixed. An empty string is the legacy/unassigned sentinel for rows created before per-quiz-mode
/// progress existed; the upgrade migration stamps those with `mapQuiz` (all legacy progress was
/// effectively the Map Tab Quiz).
enum QuizModeID: String, CaseIterable {
    case mapQuiz
    case multipleChoice
    case typeCapital
    case nameFeature

    /// The token the one-time migration stamps onto all pre-existing (empty-`quizMode`) progress.
    static let legacyMigrationTarget: QuizModeID = .mapQuiz

    /// The categories this mode serves cards for. `typeCapital` is Countries-only (only countries have
    /// capitals); every other mode serves all categories. The store provider seeds only these
    /// categories for a mode, so a mode never holds cards for a category it cannot quiz.
    var servedCategories: [CardCategory] {
        switch self {
        case .typeCapital: [.country]
        case .mapQuiz, .multipleChoice, .nameFeature: CardCategory.allCases
        }
    }
}
