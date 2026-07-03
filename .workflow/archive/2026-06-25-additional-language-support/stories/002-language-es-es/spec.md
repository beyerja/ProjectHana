# 002 — Language: Español (España) (es-ES)

## Title
Add Spanish (Spain) `es-ES` as a complete, downloadable language

## Goal
Add `es-ES` as a NEW distinct base language code (separate from `es-MX`), delivered as a
downloadable ODR pack, with COMPLETE professional translations for all UI strings and all geo
content. `es-ES` must be selectable in the picker as "Español (España)" but MUST NEVER be
auto-selected from device locale (every `es-*` device locale still resolves to `.esMX`).

This story ships FIRST among the new languages because `ca` and `eu` (stories 003, 004) fall
back through `es-ES`. Its commit must compile and pass on its own.

## Files to change
- `Hanahuac/L10n/AppLocale.swift` — add `case esES = "es-ES"`. Do NOT add `es-ES` to
  `matching(_:)`; the existing `if language == "es" { return .esMX }` MUST remain so Spain-region
  devices still default to `es-MX`.
- `Hanahuac/L10n/LanguageCatalog.swift` — add a `LanguageDescriptor` for `es-ES`
  (displayName "Español (España)", fallbackChain `[.esES, .esMX, .en]`,
  availability `.downloadablePack`, odrTags `[lang-es-ES]`). Catalog order must match
  `AppLocale.allCases`.
- `Hanahuac/es-ES.lproj/Localizable.strings` — NEW; complete professional Castilian Spanish for
  all ~85 keys (copy `en.lproj` key set, translate every value).
- `Hanahuac/Resources/countries.json` — add `name_es_es` + `capital_es_es` columns for every
  country (complete).
- `Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json` — add `name_es_es` for every
  entity (complete).
- `scripts/generate-geo-packs.py` — add `"es-ES"` to `PACK_LANGUAGES` and
  `"es-ES": "es_es"` to `SUFFIX_BY_CODE`.
- `Hanahuac/Resources/es-ES-geo.json` — generated via `just geo-packs` (do not hand-edit).
- `project.yml` — add `es-ES.lproj` and `Resources/es-ES-geo.json` as resources tagged
  `[lang-es-ES]` and add both to `excludes`. Regenerate via `just generate`.
- `HanahuacTests/AppLocaleTests.swift` — regression test:
  `AppLocale.matching(Locale(identifier: "es_ES")) == .esMX`.
- Tests for: picker native name, fallback chain `[es-ES, es-MX, en]` resolution, completeness
  (no missing UI keys, full geo coverage), and progress isolation for `.esES`
  (reuse story 001 helpers).

## Acceptance Criteria
1. Picker shows "Español (España)" for `es-ES`.
2. `es-ES` is a distinct base code separate from `es-MX`.
3. Device-locale default UNCHANGED: `AppLocale.matching(Locale(identifier: "es_ES")) == .esMX`;
   `es-ES` is never auto-selected.
4. Fallback chain `[es-ES, es-MX, en]` resolves UI strings and geo names correctly (test).
5. COMPLETE content: zero missing UI keys vs `en.lproj`; every country/capital/river/mountain/sea
   has an `es-ES` value (completeness check passes).
6. ODR: `es-ES.lproj` + `es-ES-geo.json` exist, tagged `[lang-es-ES]`, excluded from bundle;
   `just geo-packs-check` and `just verify-odr-packs` pass; `es-ES` is NOT bundled.
7. Per-language progress isolated for `.esES` (ReviewCard / DailyProgressSnapshot).
8. Catalog/enum invariants hold (one descriptor per case; order matches; tag correctness).
9. `just lint`, `just test`, `just geo-packs-check`, `just verify-odr-packs`, and an
   iOS/Catalyst build pass. CI green on the PR.

## Notes
- Suffix: `es_es`.
- Author real Castilian Spanish (peninsular spelling/vocabulary), NOT a copy of `es-MX`.
