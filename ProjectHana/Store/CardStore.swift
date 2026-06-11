import Foundation
import SwiftData
import Observation

@Observable
final class CardStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        ensureGraduationConsistency()
    }

    var allCards: [ReviewCard] {
        (try? modelContext.fetch(FetchDescriptor<ReviewCard>())) ?? []
    }

    func dueCards(for category: CardCategory? = nil) -> [ReviewCard] {
        let now = Date.now
        var descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate { $0.nextReviewDate <= now && $0.hasGraduated }
        )
        descriptor.sortBy = [SortDescriptor(\.nextReviewDate)]
        let cards = (try? modelContext.fetch(descriptor)) ?? []
        guard let category else { return cards }
        return cards.filter { $0.cardCategory == category }
    }

    func newCards(for category: CardCategory? = nil) -> [ReviewCard] {
        var descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate { !$0.hasGraduated }
        )
        descriptor.sortBy = [SortDescriptor(\.factID)]
        let cards = (try? modelContext.fetch(descriptor)) ?? []
        guard let category else { return cards }
        return cards.filter { $0.cardCategory == category }
    }

    private func ensureGraduationConsistency() {
        let cards = allCards
        var changed = false
        for card in cards where !card.hasGraduated && (card.repetitionCount > 0 || card.intervalDays > 1) {
            card.hasGraduated = true
            changed = true
        }
        if changed { try? modelContext.save() }
    }

    func upsert(_ card: ReviewCard) {
        modelContext.insert(card)
        try? modelContext.save()
    }

    func resetAll() {
        let cards = allCards
        for card in cards {
            modelContext.delete(card)
        }
        try? modelContext.save()
    }

    func seedIfNeeded(with data: GeographyData) {
        guard allCards.isEmpty else { return }

        var cards: [ReviewCard] = []

        for country in data.countries {
            cards.append(ReviewCard(factID: country.id, category: .country))
        }
        for river in data.rivers {
            cards.append(ReviewCard(factID: river.id, category: .river))
        }
        for mountain in data.mountains {
            cards.append(ReviewCard(factID: mountain.id, category: .mountain))
        }
        for sea in data.seas {
            cards.append(ReviewCard(factID: sea.id, category: .sea))
        }

        for card in cards {
            modelContext.insert(card)
        }
        try? modelContext.save()
    }
}
