# 001 — Localize the Multiple-Choice quiz

## Title
Localize the Multiple-Choice quiz prompt + country/feature names (AC1)

## Goal
With the app UI in Spanish (and every other locale), the Multiple-Choice (MC) quiz must render its
prompt AND the country/feature names in the selected app language — matching the already-correct
Type-Capital quiz. The MC prompt currently leaks English ("What is the capital of Ukraine?",
"What is the capital of Netherlands?") while Type-Capital is correctly Spanish ("¿Cuál es la capital
de Micronesia?").

Route the MC prompt template AND the country/feature names through the existing l10n /
`GeoNameResolver` system so the MC quiz matches the selected app language in every quiz mode
(countries, rivers, mountains, seas). Country phrasing must read naturally per locale
("Países Bajos", not "Netherlands").

## Scope
- MC quiz prompt template + answer/option labels routed through l10n.
- Feature names (countries, rivers, mountains, seas) resolved via `GeoNameResolver` / language packs
  — do NOT hardcode names in the view.
- Any new string keys added to **ALL** locales so `just l10n-check` and runtime completeness tests
  pass.

## Out of Scope
- New quiz modes or changes to Type-Capital / Map / Name-Feature prompt logic beyond shared helpers.
- Vector map redesign, scheduler/data-model changes (per feature Out of Scope).

## Constraints
- Reuse `GeoNameResolver` / language packs for feature names; no hardcoded English names.
- New keys MUST land in every locale (`just l10n-check` is a hard gate).
- Project is generated from `project.yml` via `just generate` (xcodegen) — never hand-edit pbxproj.
- `just lint` + `just test` must pass.
- Follow CLAUDE.md allowlistable-command conventions (no `cd &&`, heredocs, `$(…)`, poll loops;
  Read/Grep/Glob over shell inspection).

## Acceptance Criteria
1. With the app set to Spanish, the MC prompt is fully Spanish (template + country/feature name),
   e.g. "¿Cuál es la capital de Países Bajos?" — no English leakage.
2. Same correctness holds across all four feature categories (countries, rivers, mountains, seas)
   and across the other downloadable locales (spot-check at least one non-Spanish, non-English
   locale).
3. `just l10n-check` passes with the new keys present in ALL locales.
4. `just lint` and `just test` pass.

## Verification (LIVE — AC9 baked in)
Verification is LIVE via `just ui-walkthrough <script> <run>` against the booted iPhone 17 /
iOS 26.5 sim — read the produced screenshots AND accessibility-element dumps, not just file diffs.
- Author the action script under
  `.workflow/ui-walkthrough/scripts/001-localize-mc.json` (set app language to Spanish, open
  Home → MC quiz, dump tree, screenshot the prompt; repeat for at least one other category).
- Capture **before/after** evidence (screenshots + accessibility dumps) proving the MC prompt was
  English before and is correctly localized after; reference the run artifacts in the story/verify
  log (AC9).
- Confirm via the accessibility dump that the prompt string contains the localized country name
  (e.g. "Países Bajos") and the localized template, with no English.

## Branch
`feat/ship-readiness-uiux` (HANA_FEATURE_SLUG="ship-readiness-uiux"); story commits land on this
feature branch / its PR.
