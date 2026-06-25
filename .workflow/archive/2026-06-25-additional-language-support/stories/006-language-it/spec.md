# 006 — Language: Italiano (it)

## Title
Add Italian `it` as a COMPLETE downloadable language

## Goal
Add `it` (Italian) as a downloadable ODR language with native display name "Italiano" and
COMPLETE professional translations for all ~85 UI keys and all geo content. The chain
`[it, en]` must resolve to English ONLY as an ultimate safety net that, per acceptance, is never
actually hit. No dependency on other new languages.

## Files to change
- `Hanahuac/L10n/AppLocale.swift` — add `case it`. `it` MAY auto-detect via the catalog-driven
  `matching(_:)` code-lookup (code `it` == rawValue); confirm `es-*` mapping is unaffected.
- `Hanahuac/L10n/LanguageCatalog.swift` — add descriptor (displayName "Italiano",
  fallbackChain `[.it, .en]`, availability `.downloadablePack`, odrTags `[lang-it]`).
  Order matches `AppLocale.allCases`.
- `Hanahuac/it.lproj/Localizable.strings` — NEW; COMPLETE professional Italian for all ~85 keys.
- `Hanahuac/Resources/countries.json` — add `name_it` + `capital_it` for EVERY country.
- `Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json` — add `name_it` for EVERY entity.
- `scripts/generate-geo-packs.py` — add `"it"` to `PACK_LANGUAGES`, `"it": "it"` to `SUFFIX_BY_CODE`.
- `Hanahuac/Resources/it-geo.json` — generated via `just geo-packs`.
- `project.yml` — add `it.lproj` + `Resources/it-geo.json` tagged `[lang-it]`; add both to
  `excludes`. Regenerate via `just generate`.
- Tests: picker native name; fallback chain `[it, en]` resolution; COMPLETENESS check (zero
  missing UI keys, full geo coverage — reuse story 001 helper); progress isolation for `.it`.

## Acceptance Criteria
1. Picker shows "Italiano" for `it`.
2. Fallback chain `[it, en]` resolves correctly (test).
3. COMPLETE content: zero missing UI keys vs `en.lproj`; every country/capital/river/mountain/sea
   has an `it` value (completeness check passes — fallback to en never hit).
4. ODR: `it.lproj` + `it-geo.json` exist, tagged `[lang-it]`, excluded from bundle;
   `just geo-packs-check` and `just verify-odr-packs` pass; `it` is NOT bundled.
5. Per-language progress isolated for `.it`.
6. Catalog/enum invariants hold.
7. `just lint`, `just test`, `just geo-packs-check`, `just verify-odr-packs`, and an
   iOS/Catalyst build pass. CI green on the PR.

## Notes
- Suffix: `it`. COMPLETE-content language — completeness check is enforced.
