# Story 001 — Name-that-feature session logic (pending + new piles)

## Title
Generic "Name that feature" quiz sessions for any MappableFeature (pending + new piles)

## Goal
Provide the testable, UI-independent session logic for the new map-pin "Name that feature" quiz so it
works for every category (countries, rivers, mountains, seas) and for both the *pending* (SM-2 due) and
*new* (active-set learning) piles, reusing the existing matching, SM-2, and graduation machinery.

This story ships pure model/session types and tests; no view or routing changes (those are stories
002/003). The build stays green because nothing yet references these types.

## Acceptance Criteria
- [ ] A way to build "name that feature" questions/cards from a set of `ReviewCard`s + the category's
      `[any MappableFeature]` (from `MapFeatureCatalog.features(for:)`), pairing each card with its
      feature. The accepted answer is the feature's `localizedName(for: locale)` (primary) plus its
      English `name` as a fallback when `locale != .en` — mirroring `TextQuizSession`'s
      trimmed/case-insensitive primary+fallback matching. Reuse `TextQuizSession` and a new factory
      (e.g. `TextQuizSession.nameFeatureQuestions(cards:features:locale:)`) rather than a parallel type,
      OR a small dedicated session if `TextQuizSession` cannot cleanly express it — prefer reuse.
- [ ] Pending pile: answering schedules the card via `SM2Scheduler` at quality 4 (correct) / 1 (wrong),
      records a streak review, and exposes `reviewedCount` / `correctCount` / `nextDueDate` for the
      summary — identical semantics to the existing capital text quiz.
- [ ] New pile: a learning variant reuses the 3-consecutive-correct graduation + active-set mechanic
      (as `MapLearningSession`/`LearningSession` do): correct increments the streak and graduates at 3,
      wrong resets the streak and requeues; graduation applies SM-2 quality 4 and persists active-set
      membership when a category + `ActiveSetStore` is supplied.
- [ ] English `name` is accepted as a fallback only when the locale is not English; for `.ko`/`.nah`
      the feature's localized name (resolved through the existing ko→es→en / nah→es→en chain) is the
      accepted primary answer.
- [ ] Unit tests cover: matching a correct localized answer, matching the English fallback under a
      non-English locale, rejecting a wrong answer (and revealing the correct name), SM-2 quality
      mapping on the pending path, and graduation-after-3-correct on the new path. Tests pass under the
      project test recipe.

## Notes
Reuse, do not duplicate: `MappableFeature.localizedName(for:)`, the `.name` English field on each model,
`TextQuizSession`'s matching, `SM2Scheduler`, `StreakTracker`, and the active-set learning mechanic.
