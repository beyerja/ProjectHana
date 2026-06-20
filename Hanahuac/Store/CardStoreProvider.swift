import Foundation
import Observation
import SwiftData

/// Vends and caches one `CardStore` per quiz mode for the active language.
///
/// Progress is tracked independently per `(language, quizMode)`, but the Home screen shows several
/// modes at once and each quiz view needs the store for its own mode — so a single ambient `CardStore`
/// no longer suffices. This provider lazily builds and caches one seeded `CardStore` per
/// `QuizModeID` for one active language, and the app rebuilds the provider when the active language
/// changes (the same trigger that used to rebuild the single store). Each cached store is scoped to
/// `(language, mode)` and seeded — restricted to the categories the mode serves — on first
/// construction, so a mode's cards exist before it is quizzed and `typeCapital` only ever holds
/// Countries cards.
///
/// Injected into the SwiftUI environment in place of the old single `CardStore`. Views resolve their
/// mode's store via `store(for:)`; the Home screen reads `revision` to invalidate its count pills
/// after any mode's mutation, and `StatsView` reads `allCards` for the mode-aggregated mastery view.
@Observable
final class CardStoreProvider {
    @ObservationIgnored private let modelContext: ModelContext

    /// The `AppLocale.rawValue` all vended stores belong to.
    let language: String

    /// Geo catalog used to seed each per-mode store on first access.
    @ObservationIgnored private let geographyData: GeographyData

    /// Cache of one store per mode, built lazily and seeded on construction.
    @ObservationIgnored private var stores: [QuizModeID: CardStore] = [:]

    init(modelContext: ModelContext, language: String, geographyData: GeographyData) {
        self.modelContext = modelContext
        self.language = language
        self.geographyData = geographyData
    }

    /// Returns the seeded `CardStore` for a persisted mode token, building and caching it on first
    /// access. The store is scoped to `(language, mode.rawValue)` and seeded only for the categories
    /// the mode serves. Distinct name from the `HomeQuizMode` overload below to avoid a `.case`
    /// literal resolving ambiguously between the two enums at call sites.
    func store(forModeID mode: QuizModeID) -> CardStore {
        if let existing = stores[mode] {
            return existing
        }
        let store = CardStore(modelContext: modelContext, language: language, quizMode: mode.rawValue)
        store.seedIfNeeded(with: geographyData, categories: mode.servedCategories)
        stores[mode] = store
        return store
    }

    /// Resolves the store for a UI mode (bridges `HomeQuizMode` → `QuizModeID`). This is the
    /// view-facing API.
    func store(for mode: HomeQuizMode) -> CardStore {
        store(forModeID: mode.quizModeID)
    }

    /// Eagerly builds + seeds every mode's store. Called once at app startup (after the one-time
    /// migration) so each mode's track exists before the user navigates, and so `revision`/`allCards`
    /// reflect every mode immediately.
    func seedAllModes() {
        for mode in QuizModeID.allCases {
            _ = store(forModeID: mode)
        }
    }

    /// Mode-aggregated mutation signal: the sum of every cached store's `revision`. A view that reads
    /// this in its `body` invalidates after a graded answer in ANY mode (each `CardStore.revision`
    /// bumps on its own mutations, and reading them here aggregates the dependency).
    var revision: Int {
        stores.values.reduce(0) { $0 &+ $1.revision }
    }

    /// Every card across all modes for the active language (the mode-aggregated view the Progress
    /// screen's default totals are computed from). Each `(factID, mode)` is a distinct card, so this is
    /// simply the union of the per-mode stores' cards — no cross-mode dedup is applied (two modes
    /// holding a card for the same fact are intentionally separate progress rows).
    var allCards: [ReviewCard] {
        QuizModeID.allCases.flatMap { store(forModeID: $0).allCards }
    }

    /// Mode-aggregated due cards across all modes (the whole-language "pending" total the Progress
    /// screen shows by default). Pass a category to filter.
    func dueCards(for category: CardCategory? = nil) -> [ReviewCard] {
        QuizModeID.allCases.flatMap { store(forModeID: $0).dueCards(for: category) }
    }
}
