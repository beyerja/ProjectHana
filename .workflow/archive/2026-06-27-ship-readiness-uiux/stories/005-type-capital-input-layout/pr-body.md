## Goal

Make the Type-Capital quiz input layout robust when the software keyboard is up — including the iOS
multilingual-keyboard onboarding card that the live driver caught overlapping the bottom of the
screen. The answer field (`quiz.input`) and the "Verificar" button (`quiz.submit`) must stay visible
and tappable while the keyboard is raised (AC8).

## Changes

- Split `quizBody` so the progress + prompt content scrolls (`.scrollDismissesKeyboard(.interactively)`)
  while `answerSection` (the answer field + "Verificar" button) is pinned to the bottom via
  `.safeAreaInset(edge: .bottom)`. This lifts the input and button above the keyboard / onboarding card
  rather than letting them sit in the occluded lower region.
- Added the AC9 live driver script `.workflow/ui-walkthrough/scripts/005-type-capital-layout.json`
  (open Type-Capital quiz, focus the field to raise the keyboard, type text, then screenshot + dump the
  accessibility tree).

## Evidence (AC9, live sim — iPhone 17 / iOS 26.5)

- PRE-FIX (`.workflow/ui-walkthrough/005-prefix/`): `quiz.submit` "Verificar" at y=328 (bottom ~380),
  `quiz.input` at y=278 — sit in the keyboard-occluded region without the inset lift.
- POST-FIX (`.workflow/ui-walkthrough/005-postfix/`): `quiz.submit` "Verificar" lifted to y=470
  (h=52), `quiz.input` to y=420 — both present and hittable with the keyboard up. The fix raises the
  input + button ~142pt via the bottom safe-area inset.

Layout-only change; no new user-visible strings and no `project.yml` change (no regen needed).

## Test plan

- [x] `just lint` (includes `just l10n-check`) passes
- [x] `just test` — TEST SUCCEEDED
- [x] AC9 live walkthrough: post-fix dump shows `quiz.input` + `quiz.submit` both present/hittable with keyboard up
- [x] AC9 before/after evidence captured (prefix vs postfix runs)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
