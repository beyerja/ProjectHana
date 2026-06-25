# 009 — Language: Српски / Serbian (Cyrillic) (sr)

## Title
Add Serbian (Cyrillic) `sr` as a COMPLETE downloadable language

## Goal
Add `sr` (Serbian, Cyrillic script) as a downloadable ODR language with native display name
"Српски" and COMPLETE professional translations (in Cyrillic) for all ~85 UI keys and all geo
content. Chain `[sr, en]` resolves to English only as a never-hit safety net. No dependency on
other new languages.

## Files to change
- `Hanahuac/L10n/AppLocale.swift` — add `case sr`. `sr` MAY auto-detect via the catalog-driven
  `matching(_:)` code-lookup (code `sr` == rawValue); confirm `es-*` mapping is unaffected.
- `Hanahuac/L10n/LanguageCatalog.swift` — add descriptor (displayName "Српски",
  fallbackChain `[.sr, .en]`, availability `.downloadablePack`, odrTags `[lang-sr]`).
  Order matches `AppLocale.allCases`. ADD a code comment documenting the Cyrillic-script
  decision rationale (official constitutionally designated script; authoritative geographic
  names best served by the official script — per feature spec §5).
- `Hanahuac/sr.lproj/Localizable.strings` — NEW; COMPLETE professional Serbian Cyrillic for all
  ~85 keys.
- `Hanahuac/Resources/countries.json` — add `name_sr` + `capital_sr` (Cyrillic) for EVERY country.
- `Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json` — add `name_sr` (Cyrillic) for
  EVERY entity.
- `scripts/generate-geo-packs.py` — add `"sr"` to `PACK_LANGUAGES`, `"sr": "sr"` to `SUFFIX_BY_CODE`.
- `Hanahuac/Resources/sr-geo.json` — generated via `just geo-packs`.
- `project.yml` — add `sr.lproj` + `Resources/sr-geo.json` tagged `[lang-sr]`; add both to
  `excludes`. Regenerate via `just generate`.
- Tests: picker native name "Српски"; fallback chain `[sr, en]` resolution; COMPLETENESS check
  (zero missing UI keys, full geo coverage); progress isolation for `.sr`.

## Acceptance Criteria
1. Picker shows "Српски" (Cyrillic) for `sr`.
2. Fallback chain `[sr, en]` resolves correctly (test).
3. COMPLETE content (all Cyrillic): zero missing UI keys vs `en.lproj`; every
   country/capital/river/mountain/sea has an `sr` value (completeness check passes — fallback to
   en never hit).
4. Script decision documented in a code comment at the descriptor.
5. ODR: `sr.lproj` + `sr-geo.json` exist, tagged `[lang-sr]`, excluded from bundle;
   `just geo-packs-check` and `just verify-odr-packs` pass; `sr` is NOT bundled.
6. Per-language progress isolated for `.sr`.
7. Catalog/enum invariants hold.
8. `just lint`, `just test`, `just geo-packs-check`, `just verify-odr-packs`, and an
   iOS/Catalyst build pass. CI green on the PR.

## Notes
- Suffix: `sr`. Use code `sr` for Cyrillic consistently (display name "Српски").
- COMPLETE-content language — completeness check is enforced. All values authored in Cyrillic.
