## Goal

Add Basque (`eu`, native display name "Euskara") as a downloadable On-Demand Resources (ODR)
language pack. UI strings and geo content are authored in real, professional Basque to the extent
feasible; genuine gaps fall back through the chain `[eu, es-ES, en]` (Spanish before English).

Depends on story 002 (es-ES), already merged — `es-ES` is the fallback base for `eu`.

## Summary of changes

- **`Hanahuac/L10n/AppLocale.swift`** — add `case eu`; `eu` auto-detects via the catalog-driven
  `matching(_:)` code-lookup (code `eu` == rawValue), `es-*` mapping unaffected.
- **`Hanahuac/L10n/LanguageCatalog.swift`** — add descriptor: displayName "Euskara",
  fallbackChain `[.eu, .esES, .en]`, availability `.downloadablePack`, odrTags `[lang-eu]`,
  ordered to match `AppLocale.allCases`.
- **`Hanahuac/eu.lproj/Localizable.strings`** — NEW; professional Basque for the UI keys
  (best-effort; remaining gaps fall back through es-ES → en).
- **`Hanahuac/Resources/countries.json`** — add `name_eu` + `capital_eu` (best-effort coverage).
- **`Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json`** — add `name_eu`
  (best-effort).
- **`scripts/generate-geo-packs.py`** — add `"eu"` to `PACK_LANGUAGES` and `"eu": "eu"` to
  `SUFFIX_BY_CODE`.
- **`Hanahuac/Resources/eu-geo.json`** — generated via `just geo-packs`.
- **`project.yml`** — wire `eu.lproj` + `Resources/eu-geo.json` as ODR tagged `[lang-eu]`; both
  added to `excludes` so `eu` is NOT bundled. Project regenerated via `just generate`.
- **Tests** — picker native name "Euskara"; fallback chain `[eu, es-ES, en]` resolution (a gap in
  `eu` resolves to the `es-ES` value before `en`); per-language progress isolation for `.eu`.

## Acceptance criteria

1. Picker shows "Euskara" for `eu`.
2. Fallback chain `[eu, es-ES, en]` resolves correctly — a gap in `eu` resolves to the `es-ES`
   value before `en` (test asserts the chain order through Spanish). `eu` is fallback-permitted.
3. Real Basque authored to the extent feasible; remaining gaps fall back (permitted).
4. ODR: `eu.lproj` + `eu-geo.json` exist, tagged `[lang-eu]`, excluded from the bundle; `eu` is
   NOT bundled.
5. Per-language progress isolated for `.eu`.
6. Catalog/enum invariants hold.

## Test plan

- [ ] `just lint`
- [ ] `just test`
- [ ] `just geo-packs-check`
- [ ] `just verify-odr-packs`
- [ ] iOS / Catalyst build
- [ ] CI green on the PR
