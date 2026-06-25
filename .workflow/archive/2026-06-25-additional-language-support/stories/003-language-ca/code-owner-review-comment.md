<!-- code-owner-review -->
## Code-owner review — APPROVED

Independent second-eye verification of the Catalan (`ca`) story, reviewing the diff directly (not via the `/code-review` skill). I re-derived my own verdict; the prior `independent-review` APPROVED was treated as input, not conclusion.

### Story-specific gates — all pass

1. **Catalan quality (real, professional).** UI strings in `ca.lproj/Localizable.strings` use genuine Catalan orthography: `Configuració` (ç), `Brussel·les` not checked here but geo names show `Països`, `S'està baixant…`, `l'aplicació`, `Pròxim`/`Següent`, `Tendències`, accents `Àfrica`/`Àsia`/`Amèrica`/`Etiòpia`. Geo names distinct from Spanish: `Algèria`/`Alger`, `El Caire`, `Txad`, `República Centreafricana`, `República Democràtica del Congo`, `Costa d'Ivori`, `Gàmbia`. Not machine garbage, not Spanish verbatim, not placeholder.
2. **Fallback chain `[ca, es-ES, en]`.** Declared in `LanguageCatalog`. `testCatalanGapKey_resolvesToSpainSpanishBeforeEnglish` asserts the deliberately-omitted key resolves to the **es-ES** value before `en`. Verified the gap key `settings.sync.toggle` genuinely exists in `es-ES.lproj` ("Sincronización con iCloud") and is genuinely absent from `ca.lproj` (only a NOTE comment marks the omission). `testCatalanPack_omitsGapKey_whileSpainSpanishTranslatesIt` guards both halves.
3. **es-MX default preserved.** `AppLocale.matching(_:)` maps every `es-*` to `.esMX` via an early `language == "es"` branch before the catalog code-lookup; `ca` auto-detects via the code lookup. `testMatchingSpanishVariants` and `testMatchingCatalanDoesNotPerturbSpanish` assert `es_ES → .esMX` and `ca → .ca` together.
4. **ODR / not bundled.** `ca.lproj` + `Resources/ca-geo.json` tagged `[lang-ca]` and both in `excludes` in `project.yml`; `verify-odr-packs.sh` LANG_CODES extended to `(fr de es-ES ca ko nah)`. `ca` not bundled.
5. **Progress isolation.** `testProgressIsolationForCatalan` exercises `.ca` vs `.esES` through the shared isolation helper (isolated tracks, shared factID/day coexistence).
6. **Catalog/enum invariants.** Catalog order matches `AppLocale.allCases`; one descriptor per case; count assertions bumped (`allCasesCount → 8`, `ca` immediately after `es-ES`).

### Runtime reachability
`BundledLanguagePackProvider.buildPacks` includes `.ca` in `packLanguages`, so the Catalan geo pack is actually built and served at runtime, not just in tests.

### CI
All required checks green on head `481bbdd`: `Build & Test`, `gitleaks`, `Lint (all languages)` — all `success`. No event-miss; no self-heal needed.

**Verdict: APPROVED.** Formal code-owner state submitted as `Hanahuac-Bot` via the wrapper, with read-back confirmation.
