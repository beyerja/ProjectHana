## Code-owner review — APPROVED (independent second eye)

Independent re-verification of PR #159 (story 004 — Basque `eu`), formed by reading the diff
directly (not via the `/code-review` skill) and tracing each new seam to its production call site.
This is a distinct second judgment, not a rubber-stamp of the first reviewer.

### Story-004 contract — all confirmed
- **Fallback `[eu, es-ES, en]`, authored Euskara is real.** `LanguageCatalog` descriptor is
  `Euskara` / `[.eu, .esES, .en]` / `.downloadablePack`; `L10n.bundleCandidates(for: .eu)` ==
  `["eu", "es-ES", "en"]`. `eu.lproj/Localizable.strings` is genuine professional Basque (correct
  ergative/genitive grammar `%@(r)en`, inessive `kontinentetan`, `«»` quotes; Herrialdeak/Ibaiak/
  Mendiak/Itsasoak/Ezarpenak/Hizkuntza) — not MT, not Spanish verbatim. Geo `name_eu`/`capital_eu`
  carry distinct Basque exonyms (Aljeria, Kamerun) and legitimate Basque-equals-Spanish forms.
- **Gap resolves to es-ES before en.** `settings.sync.toggle` is deliberately omitted from eu
  (documented inline). `testBasqueGapKey_resolvesToSpainSpanishBeforeEnglish` asserts the gap serves
  the es-ES value AND `!= en` — the chain order through Spanish is truly exercised.
- **ODR, tagged `[lang-eu]`, NOT bundled.** `project.yml` lists `eu.lproj` + `Resources/eu-geo.json`
  in BOTH `excludes` and resources with `resourceTags: [lang-eu]`; `verify-odr-packs.sh` LANG_CODES
  includes `eu`.
- **es-MX stays device-locale default; eu auto-detects without perturbing es-\*.** `matching(_:)`
  keeps `es` → `.esMX` first, then catalog code-lookup auto-detects `eu`.
  `testMatchingBasqueDoesNotPerturbSpanish` asserts `es_ES`/`es-ES` → `.esMX` while `eu`/`eu-ES`/
  `eu_ES` → `.eu`.
- **Per-language progress isolation for `.eu`.** `testProgressIsolationForBasque` (`.eu` vs `.esES`).
- **Catalog/enum invariants.** Count 9 (`testCatalogContainsExactlyNineLanguages`,
  `testAllCasesCount`), order eu-immediately-after-ca, generic ODR-tag invariants.

### Production wiring
The `.eu` arms in `GeoModel+PackData.swift` reference `nameEu`/`capitalEu` correctly across all four
models (no copy-paste). Catalog descriptor is the live fallback source; no component left unwired.

### CI
Required checks present and green on head `6ee48b0`: Build & Test ✓, gitleaks ✓ (plus Lint ✓). No
event-miss; no self-heal required.

**Verdict: APPROVED.**
