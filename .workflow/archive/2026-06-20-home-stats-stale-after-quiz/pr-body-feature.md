## Goal

Make the Home screen count pills and the Progress screen reflect the new state **immediately** after finishing or exiting a quiz, with no app relaunch required.

## Problem

After finishing (or exiting) a quiz and returning to the home screen, the per-row "New N" / "Pending N" count pills kept showing the **old** values. The same staleness affected the **Progress screen** (cards-reviewed, due-today, streak, per-category mastery tiers, per-language breakdown, charts). The numbers only corrected themselves on **app relaunch**.

## Root cause

`HomeView` and `StatsView` derive every displayed number from fetch accessors on the `@Observable` stores (`CardStore`, `ProgressStatsStore`). Those accessors run a fresh `FetchDescriptor` against the `ModelContext` and **read no `@Observable` stored property** of the store. SwiftUI's Observation therefore registered **no dependency** for these views, so quiz-driven SwiftData mutations never invalidated Home or Progress — they kept rendering previously-fetched numbers until the whole subtree was rebuilt.

## Fix

- Added a `private(set) var revision` + `markChanged()` to both `CardStore` and `ProgressStatsStore`, bumped on **every** save path.
- `HomeView` and `StatsView` now read the revision in `body`, so Observation ties their fetch-derived counts to mutations and re-fetches when the signal changes.
- Added `CardStore.persistCardChanges()` so every graded-card save across all **6 quiz views** — including the two learning views that previously bumped nothing — routes through a revision-bumping method.

## Coverage

- All quiz types: MultipleChoice, MapQuiz, Capital / NameFeature text quizzes, and the learning piles.
- All categories (countries / rivers / mountains / seas).
- Both the "new" (learning) and "pending" (review) piles.

## Note

`main` was integrated into this branch (clean merge of #111).

## Test plan

- [ ] Regression tests assert the revision signal fires on each mutating store method (`upsert`, `recordSnapshot`, `persistCardChanges`, etc.)
- [ ] `just lint` passes
- [ ] `just test` passes
- [ ] Manual: complete a quiz of each type → Home pills update without relaunch
- [ ] Manual: complete a quiz → Progress screen counts/charts update without relaunch
- [ ] Manual: exit a quiz early → both screens reflect partial persisted state
- [ ] Manual: switching language still shows the correct track (no regression)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
