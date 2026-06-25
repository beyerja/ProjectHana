# 008 — Language: Nederlands (nl)

## Title
Add Dutch `nl` as a COMPLETE downloadable language

## Goal
Add `nl` (Dutch) as a downloadable ODR language with native display name "Nederlands" and
COMPLETE professional translations for all ~85 UI keys and all geo content. Chain `[nl, en]`
resolves to English only as a never-hit safety net. No dependency on other new languages.

## Files to change
- `Hanahuac/L10n/AppLocale.swift` — add `case nl`. `nl` MAY auto-detect via the catalog-driven
  `matching(_:)` code-lookup (code `nl` == rawValue); confirm `es-*` mapping is unaffected.
- `Hanahuac/L10n/LanguageCatalog.swift` — add descriptor (displayName "Nederlands",
  fallbackChain `[.nl, .en]`, availability `.downloadablePack`, odrTags `[lang-nl]`).
  Order matches `AppLocale.allCases`.
- `Hanahuac/nl.lproj/Localizable.strings` — NEW; COMPLETE professional Dutch for all ~85 keys.
- `Hanahuac/Resources/countries.json` — add `name_nl` + `capital_nl` for EVERY country.
- `Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json` — add `name_nl` for EVERY entity.
- `scripts/generate-geo-packs.py` — add `"nl"` to `PACK_LANGUAGES`, `"nl": "nl"` to `SUFFIX_BY_CODE`.
- `Hanahuac/Resources/nl-geo.json` — generated via `just geo-packs`.
- `project.yml` — add `nl.lproj` + `Resources/nl-geo.json` tagged `[lang-nl]`; add both to
  `excludes`. Regenerate via `just generate`.
- Tests: picker native name; fallback chain `[nl, en]` resolution; COMPLETENESS check (zero
  missing UI keys, full geo coverage); progress isolation for `.nl`.

## Acceptance Criteria
1. Picker shows "Nederlands" for `nl`.
2. Fallback chain `[nl, en]` resolves correctly (test).
3. COMPLETE content: zero missing UI keys vs `en.lproj`; every country/capital/river/mountain/sea
   has an `nl` value (completeness check passes — fallback to en never hit).
4. ODR: `nl.lproj` + `nl-geo.json` exist, tagged `[lang-nl]`, excluded from bundle;
   `just geo-packs-check` and `just verify-odr-packs` pass; `nl` is NOT bundled.
5. Per-language progress isolated for `.nl`.
6. Catalog/enum invariants hold.
7. `just lint`, `just test`, `just geo-packs-check`, `just verify-odr-packs`, and an
   iOS/Catalyst build pass. CI green on the PR.

## Notes
- Suffix: `nl`. COMPLETE-content language — completeness check is enforced.
