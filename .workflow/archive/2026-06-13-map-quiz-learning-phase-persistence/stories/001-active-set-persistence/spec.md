# Story 001: Active-Set Persistence

## Title
Persist the learning active set per category so it survives session re-entries

## Goal
`LearningSession` currently picks a fresh random 10-card slice every time it is constructed. If a user dismisses mid-session and returns, they see a different 10 cards. The active set for each category must be stored (via `UserDefaults`) so re-opening always resumes the same set until cards graduate out.

## Background
- `LearningSession.init(newCards:)` does `newCards.shuffled().prefix(10)` — no persistence.
- `ReviewCard` has `factID` (stable string ID) that can serve as the persisted identifier.
- Persistence must be per-`CardCategory` (at minimum `.country`; the same mechanism benefits all categories).
- When all cards in the stored active-set IDs have graduated (or are no longer "new"), the persisted selection must be cleared so a fresh 10 are drawn.

## Acceptance Criteria
- [ ] On first construction for a category with no stored selection, `LearningSession` shuffles the new cards, takes up to 10, and persists their `factID`s to `UserDefaults` keyed by category.
- [ ] On subsequent construction with the same category key, `LearningSession` rehydrates the same cards (matched by `factID`) as the active set, preserving order; any that have since graduated are excluded.
- [ ] If the rehydrated set is empty (all IDs graduated), the stored selection is cleared and a fresh 10 are drawn and persisted.
- [ ] When a card graduates during a session and the pool refills, the persisted selection is updated to reflect the new active-set membership.
- [ ] The persistence layer is isolated behind a protocol/interface so it can be injected in tests without hitting `UserDefaults`.
- [ ] Existing `LearningTests` continue to pass.
- [ ] New unit tests cover: same IDs returned on second construction, stale (graduated) IDs are filtered out, empty-after-filtering triggers fresh draw.
