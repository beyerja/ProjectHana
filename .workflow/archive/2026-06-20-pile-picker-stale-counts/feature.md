# Feature: PilePickerView counts refresh immediately after a quiz

## Problem

After PR #114 fixed stale new/pending counts on the Home screen (`HomeView`) and the
Progress screen (`StatsView`), an intermediate screen was missed: the **pile picker**
(`Hanahuac/Views/Home/PilePickerView.swift`) — the screen where the user chooses between
"new" and "pending" cards for a quiz mode/category.

When the user finishes/exits a quiz and navigates **back** to the pile picker, its
new/pending counts are still stale. The user must relaunch the app to see correct numbers.

## Root cause

Same Observation gap that #114 closed for `HomeView`/`StatsView`. `PilePickerView`
computes:

```swift
private var newCount: Int { mode.supportsNew ? cardStore.newCards(for: category).count : 0 }
private var pendingCount: Int { cardStore.dueCards(for: category).count }
```

These fetch accessors run a fresh `FetchDescriptor` and read no `@Observable` stored
property on `CardStore`, so SwiftUI Observation registers no dependency and never
invalidates the view after a quiz mutates `ReviewCard` rows. `PilePickerView.body` does
**not** read `cardStore.revision` (the signal added in #114), unlike `HomeView.body`
which now does `_ = cardStore.revision`.

## Expected behavior

After finishing or exiting a quiz and returning to the pile picker, its new/pending
counts update **immediately** with no relaunch — consistent with the Home screen fix.
A pile whose count drops to 0 should disappear (its `NavigationLink` is gated on
`> 0`), and a pile whose count changes should show the new number.

## Approach

Apply the **existing** `revision`-dependency pattern already established in the codebase
(do not invent a new mechanism): read `cardStore.revision` once in `PilePickerView.body`
(value discarded) so Observation ties view invalidation to the store. The quiz grading
paths already route saves through `CardStore.persistCardChanges()` (added in #113/#114),
which bumps `revision`, so no store-side change is needed.

## Acceptance criteria

1. `PilePickerView.body` reads `cardStore.revision` so SwiftUI invalidates the view when
   the store's revision changes after a quiz mutation.
2. Returning to the pile picker after a quiz shows updated new/pending counts immediately
   (no app relaunch), matching the Home screen behavior.
3. No new state-management mechanism is introduced; the fix reuses the `revision`/
   `markChanged()` signal from #114.
4. `just lint` and `just test` pass.

## Out of scope

- Changes to `CardStore`/`ProgressStatsStore` revision plumbing (already in place).
- HomeView / StatsView (already fixed in #114).
- Any new quiz-grading save paths.
