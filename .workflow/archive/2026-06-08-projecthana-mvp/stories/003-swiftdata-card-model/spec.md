# Story 003: SwiftData Card Model

## Title
Define the SwiftData persistence model for review cards and learning state

## Goal
Model each geography fact as a reviewable "card" with SM-2 scheduling metadata persisted
via SwiftData so progress survives app restarts.

## Acceptance Criteria
- [ ] `@Model class ReviewCard` is defined with properties: `id` (UUID), `factID` (String —
      references a country/river/mountain/sea by its JSON `id`), `category` (enum: country,
      river, mountain, sea), `repetitionCount` (Int), `easeFactor` (Double, default 2.5),
      `intervalDays` (Int, default 0), `nextReviewDate` (Date), `lastQualityScore` (Int?)
- [ ] `ModelContainer` is configured in the `@main` App struct with `ReviewCard` schema
- [ ] A `CardStore` observable class (using `@Observable` macro) provides: `dueCards(for:)`,
      `allCards`, `upsert(_:)`, `resetAll()`
- [ ] On first launch, `CardStore` seeds one `ReviewCard` per geography item (all 195 countries +
      rivers + mountains + seas) with `nextReviewDate = .now` so everything is due immediately
- [ ] Unit tests verify: seeding count matches dataset totals, `upsert` persists changes,
      `dueCards` returns only cards with `nextReviewDate <= Date.now`
