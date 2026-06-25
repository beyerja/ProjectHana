# 004 — Language: Euskara (eu)

## Title
Add Basque `eu` as a downloadable language (best-effort content, es-ES fallback)

## Goal
Add `eu` (Basque) as a downloadable ODR language with native display name "Euskara". Author as
much real, professional Basque as feasible for UI strings and geo content; genuine gaps may rely
on the fallback chain `[eu, es-ES, en]`. DEPENDS ON story 002 (es-ES) being merged first.

## Files to change
- `Hanahuac/L10n/AppLocale.swift` — add `case eu`. `eu` MAY auto-detect via the catalog-driven
  `matching(_:)` code-lookup (code `eu` == rawValue); no special-case edit needed; confirm `es-*`
  mapping is unaffected.
- `Hanahuac/L10n/LanguageCatalog.swift` — add descriptor (displayName "Euskara",
  fallbackChain `[.eu, .esES, .en]`, availability `.downloadablePack`, odrTags `[lang-eu]`).
  Order matches `AppLocale.allCases`.
- `Hanahuac/eu.lproj/Localizable.strings` — NEW; professional Basque for the ~85 keys
  (best-effort; genuine gaps may be omitted to fall back through es-ES → en).
- `Hanahuac/Resources/countries.json` — add `name_eu` + `capital_eu` (best-effort coverage).
- `Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json` — add `name_eu` (best-effort).
- `scripts/generate-geo-packs.py` — add `"eu"` to `PACK_LANGUAGES`, `"eu": "eu"` to `SUFFIX_BY_CODE`.
- `Hanahuac/Resources/eu-geo.json` — generated via `just geo-packs`.
- `project.yml` — add `eu.lproj` + `Resources/eu-geo.json` tagged `[lang-eu]`; add both to
  `excludes`. Regenerate via `just generate`.
- Tests: picker native name; fallback chain `[eu, es-ES, en]` resolution (a gap resolves to es-ES
  before en); progress isolation for `.eu`.

## Acceptance Criteria
1. Picker shows "Euskara" for `eu`.
2. Fallback chain `[eu, es-ES, en]` resolves correctly; a gap in `eu` resolves to the `es-ES`
   value before `en` (test asserts the chain order through Spanish).
3. Content: real Basque authored to the extent feasible; remaining gaps fall back (permitted).
4. ODR: `eu.lproj` + `eu-geo.json` exist, tagged `[lang-eu]`, excluded from bundle;
   `just geo-packs-check` and `just verify-odr-packs` pass; `eu` is NOT bundled.
5. Per-language progress isolated for `.eu`.
6. Catalog/enum invariants hold.
7. `just lint`, `just test`, `just geo-packs-check`, `just verify-odr-packs`, and an
   iOS/Catalyst build pass. CI green on the PR.

## Notes
- Suffix: `eu`.
- DEPENDENCY: requires story 002 (es-ES) merged — `es-ES` is the fallback base.
