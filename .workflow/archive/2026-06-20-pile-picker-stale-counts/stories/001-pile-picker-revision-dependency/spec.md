# 001 — PilePickerView reads cardStore.revision to refresh counts after a quiz

## Title

PilePickerView counts refresh immediately after a quiz

## Goal

Make the pile picker's new/pending counts update immediately when the user returns
to it after finishing or exiting a quiz — no app relaunch — by applying the existing
`revision`-dependency pattern (`_ = cardStore.revision`) already used by `HomeView`
after PR #114. The counts are computed by fetch accessors (`cardStore.newCards(for:)`,
`cardStore.dueCards(for:)`) that read no `@Observable` stored property, so SwiftUI
Observation currently registers no dependency and never invalidates the view after a
quiz mutates `ReviewCard` rows.

## Acceptance Criteria

1. `PilePickerView.body` reads `cardStore.revision` (value discarded) so SwiftUI
   invalidates the view when the store's revision changes after a quiz mutation,
   mirroring the `HomeView.body` fix.
2. Returning to the pile picker after finishing or exiting a quiz shows updated
   new/pending counts immediately (no app relaunch). A pile whose count drops to 0
   disappears (its `NavigationLink` is gated on `> 0`); a pile whose count changes
   shows the new number.
3. No new state-management mechanism is introduced; the fix reuses the existing
   `revision` / `markChanged()` signal from #114. No changes to `CardStore` /
   `ProgressStatsStore` revision plumbing and no new quiz-grading save paths.
4. `just lint` and `just test` pass.

## Out of scope

- Changes to `CardStore` / `ProgressStatsStore` revision plumbing (already in place).
- `HomeView` / `StatsView` (already fixed in #114).
- Any new quiz-grading save paths.

## Notes

- Target file: `Hanahuac/Views/Home/PilePickerView.swift`.
- Reference implementation: the `_ = cardStore.revision` read added to `HomeView.body`
  in PR #114.
