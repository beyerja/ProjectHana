# Feature: Map Quiz Bug Fixes

## Bug 1: Country Area Overlay Not Showing on Map Quiz

**Symptom**: When a user taps a pin on the map quiz (both "Pending" review quiz and "New" learning map quiz), the country's area should be covered with a semi-transparent red (wrong answer) or green (correct answer) polygon overlay. This was previously implemented but does not work in the installed app at `/Applications/ProjectHana.app`.

**What should happen**:
- After tapping a correct pin: the correct country's polygon fills with semi-transparent green (~35% opacity)
- After tapping a wrong pin: the tapped country's polygon fills with semi-transparent red (~35% opacity), and the correct country's polygon fills with semi-transparent green

**Implementation exists but is broken**: The code in `MapQuizSession.swift` / `AnswerState.polygonFillColor(for:)` and the `MapPolygon` rendering in `MapQuizView.swift` / `MapLearningQuizView.swift` already implement this. The `country-borders.json` resource (175 entries) is present in both the source and the app bundle. The bug is likely that `MapPolygon.foregroundStyle()` doesn't dynamically update when `answerState` changes because the `Map` content builder doesn't observe the session's `@Observable` state correctly — the polygons are rendered with a static color at build time, not reactively.

**Fix needed**: Investigate why `MapPolygon.foregroundStyle` doesn't reactively update and apply the correct fix (e.g., extracting the color into a local variable inside the `Map` content closure, or forcing a view identity change).

## Bug 2: "New" Pile Cards Not Persisting Between App Restarts

**Symptom**: The "New" pile shows 10 cards each session. Every time the app is closed and re-opened, a new random set of 10 cards appears instead of restoring the same 10 cards from the previous session.

**What should happen**: The 10 "active" new cards for a given category should be persisted to disk (UserDefaults) and restored the next time the user opens the New learning mode. Cards only leave the active set when they graduate (3 consecutive correct answers). The active set should only be reshuffled when all stored IDs have graduated.

**Root cause**: `MapLearningSession` (the map-based new-card learning flow for countries) does not use `ActiveSetStore` persistence at all. Its `init` always calls `newCards.shuffled()` and picks a fresh set. Compare with `LearningSession` (used for rivers/mountains/seas) which correctly accepts a `category` and `store` parameter and persists via `UserDefaultsActiveSetStore`. `MapLearningSession` needs the same persistence logic.

**Secondary issue**: `MapLearningQuizView.buildSession()` passes `newCards` directly from the caller without a store. It needs to accept (or create) an `ActiveSetStore` and pass it to `MapLearningSession`.

**Fix needed**: 
1. Add `category` and `store` parameters to `MapLearningSession.init`, mirroring `LearningSession`'s persistence logic.
2. Update `MapLearningQuizView` to create a `UserDefaultsActiveSetStore` and pass the category through.
3. Persist active-set updates when cards graduate in `MapLearningSession.graduate()`.

## Scope

- No new UI required; these are pure bug fixes.
- Changes are limited to: `MapLearningSession.swift`, `MapLearningQuizView.swift`, and potentially `MapQuizView.swift` / `MapLearningQuizView.swift` for the overlay bug.
- Tests in `MapLearningTests.swift` and `LearningTests.swift` should be updated/extended.
