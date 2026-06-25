# 007 — Language: Polski (pl)

## Title
Add Polish `pl` as a COMPLETE downloadable language

## Goal
Add `pl` (Polish) as a downloadable ODR language with native display name "Polski" and COMPLETE
professional translations for all ~85 UI keys and all geo content. Chain `[pl, en]` resolves to
English only as a never-hit safety net. No dependency on other new languages.

## Files to change
- `Hanahuac/L10n/AppLocale.swift` — add `case pl`. `pl` MAY auto-detect via the catalog-driven
  `matching(_:)` code-lookup (code `pl` == rawValue); confirm `es-*` mapping is unaffected.
- `Hanahuac/L10n/LanguageCatalog.swift` — add descriptor (displayName "Polski",
  fallbackChain `[.pl, .en]`, availability `.downloadablePack`, odrTags `[lang-pl]`).
  Order matches `AppLocale.allCases`.
- `Hanahuac/pl.lproj/Localizable.strings` — NEW; COMPLETE professional Polish for all ~85 keys.
- `Hanahuac/Resources/countries.json` — add `name_pl` + `capital_pl` for EVERY country.
- `Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json` — add `name_pl` for EVERY entity.
- `scripts/generate-geo-packs.py` — add `"pl"` to `PACK_LANGUAGES`, `"pl": "pl"` to `SUFFIX_BY_CODE`.
- `Hanahuac/Resources/pl-geo.json` — generated via `just geo-packs`.
- `project.yml` — add `pl.lproj` + `Resources/pl-geo.json` tagged `[lang-pl]`; add both to
  `excludes`. Regenerate via `just generate`.
- Tests: picker native name; fallback chain `[pl, en]` resolution; COMPLETENESS check (zero
  missing UI keys, full geo coverage); progress isolation for `.pl`.

## Acceptance Criteria
1. Picker shows "Polski" for `pl`.
2. Fallback chain `[pl, en]` resolves correctly (test).
3. COMPLETE content: zero missing UI keys vs `en.lproj`; every country/capital/river/mountain/sea
   has a `pl` value (completeness check passes — fallback to en never hit).
4. ODR: `pl.lproj` + `pl-geo.json` exist, tagged `[lang-pl]`, excluded from bundle;
   `just geo-packs-check` and `just verify-odr-packs` pass; `pl` is NOT bundled.
5. Per-language progress isolated for `.pl`.
6. Catalog/enum invariants hold.
7. `just lint`, `just test`, `just geo-packs-check`, `just verify-odr-packs`, and an
   iOS/Catalyst build pass. CI green on the PR.

## Notes
- Suffix: `pl`. COMPLETE-content language — completeness check is enforced.
- Ensure correct Polish diacritics (ą, ć, ę, ł, ń, ó, ś, ź, ż).
