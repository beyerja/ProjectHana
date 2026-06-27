# 002 — Harden quiz exit + resolve redundant back-navigation

## Title
Fix the intermittent quiz-exit crash and settle on one back-navigation control (AC2 + AC6)

## Goal
Exiting ANY quiz must reliably return Home without the app terminating, and each quiz screen must
offer exactly one clear way back. These two ACs are grouped because both touch the quiz
navigation/exit flow: AC6 decides which control survives (back chevron vs "Salir"), and AC2 hardens
the teardown that fires when that control is used.

### AC2 — Fix the intermittent quiz-exit crash
Observed once: tapping the exit control to leave the Multiple-Choice quiz right after the question
auto-advanced left a blank white screen and dropped to the iOS home screen (accessibility tree went
empty `[]` = app terminated); a clean repro did not reproduce it. Diagnose the quiz-session
teardown / state race (focus on **dismiss-while-advancing** in the MC flow), harden it so exiting
any quiz reliably returns Home, and add an automated regression test (unit/UI) if feasible.

### AC6 — Resolve redundant quiz back-navigation
Quiz screens show BOTH a back chevron AND a "Salir" button. Settle on one clear way back (keep the
one that fits the nav model). The driver and the committed demo currently target the "Salir" label,
so if "Salir" is removed, this story MUST update
`.workflow/ui-walkthrough/scripts/full-walkthrough.json` AND any committed demo evidence that
targets that label so the walkthrough stays green.

## Scope
- Quiz-session teardown / dismissal path for all four quiz modes (MC, Type-Capital, Map,
  Name-Feature), with emphasis on the MC dismiss-while-advancing race.
- Removal/consolidation of the redundant back control.
- Regression test for the exit path (unit or UI) if feasible.
- Update `full-walkthrough.json` + committed demo evidence if the "Salir" label is removed.

## Out of Scope
- AC1 localization, map presentation (AC5), or other UI polish ACs.
- Reworking the spaced-repetition scheduler or data model.

## Constraints
- Project is generated from `project.yml` via `just generate` — never hand-edit pbxproj.
- `just lint` + `just test` must pass.
- Any kept/removed label change must keep `just ui-walkthrough` scripts in sync.
- Follow CLAUDE.md allowlistable-command conventions.

## Acceptance Criteria
1. A tap-answer → exit loop, run several times across MC (and at least one other mode), never yields
   an empty accessibility tree — the app never terminates; the user always returns Home.
2. The dismiss-while-advancing race is diagnosed and hardened (no teardown of in-flight quiz state
   while the advance animation/transition is pending).
3. A regression test (unit/UI) covers the exit path where feasible.
4. Each quiz screen exposes exactly ONE back-navigation control.
5. If "Salir" is removed, `full-walkthrough.json` and committed demo evidence are updated and the
   walkthrough still runs green.
6. `just lint` and `just test` pass.

## Verification (LIVE — AC9 baked in)
Verification is LIVE via `just ui-walkthrough <script> <run>` against the booted iPhone 17 /
iOS 26.5 sim — read screenshots AND accessibility dumps.
- Author the action script under
  `.workflow/ui-walkthrough/scripts/002-quiz-exit.json` (open MC → answer → exit; loop the
  answer→exit cycle several times; assert the tree is non-empty / Home after each exit). Add a
  variant for at least one other quiz mode.
- Capture **before/after** evidence (screenshots + accessibility dumps): before shows two back
  controls / the crash-prone path; after shows the single control and a non-empty Home tree across
  repeated exits (AC9). Reference run artifacts in the story/verify log.

## Branch
`feat/ship-readiness-uiux` (HANA_FEATURE_SLUG="ship-readiness-uiux").
