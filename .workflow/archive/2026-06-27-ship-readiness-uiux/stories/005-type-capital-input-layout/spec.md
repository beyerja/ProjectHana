# 005 — Robust Type-Capital input layout

## Title
Make the Type-Capital input layout robust with the keyboard + iOS multilingual-keyboard onboarding
card up (AC8)

## Goal
On the Type-Capital screen, the driver caught the iOS multilingual-keyboard onboarding card
overlapping the bottom of the screen. The answer field AND the "Verificar" button must remain
visible and usable when the keyboard is up. The system onboarding card itself is not the app's bug,
but the layout must be robust to it (scroll/inset as needed).

## Scope
- Type-Capital screen layout: keyboard-avoidance / safe-area insets / scroll so the answer field and
  "Verificar" button stay visible and tappable when the keyboard (and the system onboarding card)
  are up.

## Out of Scope
- MC localization (AC1), quiz exit/back-nav (AC2/AC6), map polish (AC5), other UI polish (AC3/AC4/
  AC7).
- Changing the Type-Capital prompt/answer logic.

## Constraints
- Any new user-visible strings localized to ALL locales (`just l10n-check`).
- Project generated from `project.yml` via `just generate` — never hand-edit pbxproj.
- `just lint` + `just test` must pass.
- Follow CLAUDE.md allowlistable-command conventions.

## Acceptance Criteria
1. With the keyboard raised on the Type-Capital screen, the answer field is visible and accepts
   input.
2. The "Verificar" button remains visible and tappable with the keyboard up (and is not obscured by
   the iOS multilingual-keyboard onboarding card).
3. `just l10n-check`, `just lint`, and `just test` pass.

## Verification (LIVE — AC9 baked in)
Verification is LIVE via `just ui-walkthrough <script> <run>` against the booted iPhone 17 /
iOS 26.5 sim — read screenshots AND accessibility dumps.
- Author the action script under
  `.workflow/ui-walkthrough/scripts/005-type-capital-layout.json` (open Type-Capital quiz, focus
  the field to raise the keyboard, type text, then screenshot + dump tree; assert the field and the
  "Verificar" button are both present/hittable in the dump).
- Capture **before/after** evidence (screenshots + accessibility dumps) showing the button obscured
  before and visible/usable after; reference run artifacts in the story/verify log (AC9).

## Branch
`feat/ship-readiness-uiux` (HANA_FEATURE_SLUG="ship-readiness-uiux").
