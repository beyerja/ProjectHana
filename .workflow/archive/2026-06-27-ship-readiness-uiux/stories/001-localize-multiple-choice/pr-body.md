## Goal

With the app UI in Spanish (and every other locale), the Multiple-Choice (MC) quiz must render its
prompt **and** the country/feature names in the selected app language — matching the already-correct
Type-Capital quiz. Previously the MC prompt leaked English (e.g. "What is the capital of Netherlands?")
while Type-Capital was correctly Spanish. This story routes the MC prompt template and the
country/feature names through the existing l10n / `GeoNameResolver` system so the MC quiz matches the
selected app language across all four categories (countries, rivers, mountains, seas).

Implements story **001 — Localize the Multiple-Choice quiz prompt + country/feature names (AC1)**.

## Summary of changes

- Localizes the MC quiz prompt + country/feature names so the MC quiz matches the selected app
  language across all 4 categories (countries, rivers, mountains, seas). Country phrasing reads
  naturally per locale ("Países Bajos", not "Netherlands").
- Fixed two English leaks:
  - The **sea prompt** was hardcoded English with English N/S/E/W region labels — now routed through
    L10n via new keys `quiz.prompt.sea_location` and `quiz.region.{north,south,east,west}`.
  - The **Learn-flow MC question factory** wasn't passing the locale (defaulted to `.en`), so it
    rendered English under a Spanish UI — now passes `LanguageManager.shared.current`.
- New l10n keys added to **all** locale files; `just l10n-check` / `just lint` / `just test` pass.
- Adds `HanahuacTests/LocalizedQuizPromptTests.swift` covering the localized prompt rendering.
- Adds a ui-walkthrough verification script `.workflow/ui-walkthrough/scripts/001-localize-mc.json`.

## Acceptance criteria

- **AC1** — With the app set to Spanish, the MC prompt is fully Spanish (template + country/feature
  name), e.g. "¿Cuál es la capital de Países Bajos?" — no English leakage.
- **AC2** — Same correctness across all four feature categories (countries, rivers, mountains, seas)
  and across other downloadable locales.
- **AC3** — `just l10n-check` passes with the new keys present in ALL locales.
- **AC4** — `just lint` and `just test` pass.

> Live before/after evidence (screenshots + accessibility dumps proving English-before /
> localized-after) is captured in the dedicated verify step against the booted simulator.

## Test plan

- [ ] `just l10n-check` — new keys present in all locales
- [ ] `just lint`
- [ ] `just test` (incl. `LocalizedQuizPromptTests`)
- [ ] LIVE ui-walkthrough (`001-localize-mc.json`): Spanish MC prompt fully localized, no English, in countries + at least one other category (captured in verify step)
