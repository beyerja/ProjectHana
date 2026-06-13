# Story 004: Learning Unit Tests

## Title
Unit tests for map-quiz graduation mechanic and active-set persistence

## Goal
Consolidate and add unit tests that cover the two new behaviors: the `MapLearningSession` graduation mechanic and the active-set persistence logic. These tests must live alongside the existing `LearningTests` and must all pass in CI.

## Background
- `LearningTests.swift` already covers `LearningSession`; new tests extend coverage to `MapLearningSession` and the persistence layer.
- Persistence tests must use the injected/in-memory store (not real `UserDefaults`).
- Map graduation tests do not require a real `ModelContainer` if `ReviewCard` can be constructed standalone; check whether `@MainActor` / SwiftData context is needed.

## Acceptance Criteria
- [ ] Tests for `MapLearningSession` graduation mechanic: 3-streak graduates a card, wrong answer resets `consecutiveCorrect` to 0, graduation applies SM-2 (quality 4), session finishes when all cards graduate.
- [ ] Tests for active-set persistence: constructing a second `LearningSession` with the same category key returns the same card IDs, graduated cards are excluded from rehydration, an empty-after-filter result triggers a fresh draw.
- [ ] All existing `LearningTests` continue to pass.
- [ ] Tests run on the in-memory SwiftData container (no disk I/O).
- [ ] The app builds without warnings in CI.
