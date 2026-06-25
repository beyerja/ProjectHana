# 003 — Language: Català (ca)

## Title
Add Catalan `ca` as a downloadable language (best-effort content, es-ES fallback)

## Goal
Add `ca` (Catalan) as a downloadable ODR language with native display name "Català". Author as
much real, professional Catalan as feasible for UI strings and geo content; genuine gaps may
rely on the fallback chain `[ca, es-ES, en]`. DEPENDS ON story 002 (es-ES) being merged first,
since `es-ES` is the intermediate fallback target.

## Files to change
- `Hanahuac/L10n/AppLocale.swift` — add `case ca`. `ca` MAY auto-detect its own device locale
  via the existing catalog-driven `matching(_:)` code-lookup path (code `ca` == rawValue), so no
  special-case edit is needed; confirm it does not perturb `es-*` mapping.
- `Hanahuac/L10n/LanguageCatalog.swift` — add descriptor (displayName "Català",
  fallbackChain `[.ca, .esES, .en]`, availability `.downloadablePack`, odrTags `[lang-ca]`).
  Order matches `AppLocale.allCases`.
- `Hanahuac/ca.lproj/Localizable.strings` — NEW; professional Catalan for the ~85 keys
  (best-effort; keys with genuine gaps may be omitted to fall back through es-ES → en).
- `Hanahuac/Resources/countries.json` — add `name_ca` + `capital_ca` (best-effort coverage).
- `Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json` — add `name_ca` (best-effort).
- `scripts/generate-geo-packs.py` — add `"ca"` to `PACK_LANGUAGES`, `"ca": "ca"` to `SUFFIX_BY_CODE`.
- `Hanahuac/Resources/ca-geo.json` — generated via `just geo-packs`.
- `project.yml` — add `ca.lproj` + `Resources/ca-geo.json` tagged `[lang-ca]`; add both to
  `excludes`. Regenerate via `just generate`.
- Tests: picker native name; fallback chain `[ca, es-ES, en]` resolution (verify a deliberately
  un-translated key resolves to the es-ES value, not en); progress isolation for `.ca`.

## Acceptance Criteria
1. Picker shows "Català" for `ca`.
2. Fallback chain `[ca, es-ES, en]` resolves correctly; a gap in `ca` resolves to the `es-ES`
   value before `en` (test asserts the chain order through Spanish).
3. Content: real Catalan authored to the extent feasible; remaining gaps fall back (permitted).
4. ODR: `ca.lproj` + `ca-geo.json` exist, tagged `[lang-ca]`, excluded from bundle;
   `just geo-packs-check` and `just verify-odr-packs` pass; `ca` is NOT bundled.
5. Per-language progress isolated for `.ca`.
6. Catalog/enum invariants hold.
7. `just lint`, `just test`, `just geo-packs-check`, `just verify-odr-packs`, and an
   iOS/Catalyst build pass. CI green on the PR.

## Notes
- Suffix: `ca`.
- DEPENDENCY: requires story 002 (es-ES) merged — `es-ES` is the fallback base.
