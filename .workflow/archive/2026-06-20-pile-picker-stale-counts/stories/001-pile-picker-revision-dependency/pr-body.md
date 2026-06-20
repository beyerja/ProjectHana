## Goal

Make the pile picker's new/pending counts update immediately when the user returns to it after finishing or exiting a quiz — no app relaunch — by applying the existing `revision`-dependency pattern (`_ = cardStore.revision`) already used by `HomeView` after PR #114.

The counts are computed by fetch accessors (`cardStore.newCards(for:)`, `cardStore.dueCards(for:)`) that read no `@Observable` stored property, so SwiftUI Observation registered no dependency and never invalidated the view after a quiz mutated `ReviewCard` rows.

## Changes

- `PilePickerView.body` now reads `_ = cardStore.revision` (value discarded), mirroring the `HomeView.body` fix, so SwiftUI invalidates the view when the store revision changes after a quiz mutation. Counts refresh immediately; a pile whose count drops to 0 disappears (its `NavigationLink` is gated on `> 0`).
- Reuses the existing `revision` / `markChanged()` signal from #114 — no new state-management mechanism, no changes to `CardStore` / `ProgressStatsStore` revision plumbing, no new quiz-grading save paths.
- Added a regression test in `HanahuacTests/CardStoreTests.swift`.

## Test plan

- [ ] `just lint` passes
- [ ] `just test` passes
- [ ] Returning to the pile picker after finishing or exiting a quiz shows updated new/pending counts immediately (no relaunch)
- [ ] A pile whose count drops to 0 disappears; a pile whose count changes shows the new number

🤖 Generated with [Claude Code](https://claude.com/claude-code)
