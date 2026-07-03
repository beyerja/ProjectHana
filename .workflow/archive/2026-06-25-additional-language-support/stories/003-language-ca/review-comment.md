<!-- independent-review -->
## Independent review — APPROVED (round 1)

Fresh, cold-context 4-eye review of the Catalan (`ca`) story via `/code-review` (high effort). No blocking findings; no inline comments to post (the review surfaced no confirmed correctness bugs).

### Story-specific gates — all pass

1. **Catalan quality (real, professional).** UI strings in `ca.lproj/Localizable.strings` and geo names use genuine Catalan orthography distinct from Spanish where the languages differ: `Països`, `Configuració`, `S'està baixant`, `l'aplicació`, `Pròxim`/`Següent`, `Tendències`; geo: `Alemanya`, `Regne Unit`/`Londres`, `Suïssa`, `Itàlia`, `Polònia`, `Grècia`, `Països Baixos`, `Txèquia`, `Eslovàquia`, `Macedònia del Nord`, `Brussel·les` (l·l), `Pequín`, `Seül`, `Tòquio`, `Mèxic`, `Iang-Tsé`, `Apalatxes`, `Muntanyes Rocalloses`. Not machine garbage, not Spanish verbatim, not placeholder.
2. **Fallback chain `[ca, es-ES, en]`.** Declared in `LanguageCatalog`; `testCatalanGapKey_resolvesToSpainSpanishBeforeEnglish` asserts the deliberately-omitted key resolves to the **es-ES** value before `en` (chain order through Spanish). The gap key `settings.sync.toggle` genuinely exists in `es-ES.lproj` ("Sincronización con iCloud") and is genuinely absent from `ca.lproj`.
3. **es-MX default preserved.** `AppLocale.matching(_:)` maps every `es-*` to `.esMX` (early branch, before the catalog code-lookup); `testMatchingSpanishVariants` / `testMatchingCatalanDoesNotPerturbSpanish` assert `es_ES → .esMX` and `ca → .ca`. es-ES never auto-detected.
4. **ODR / not bundled.** `ca.lproj` + `Resources/ca-geo.json` tagged `[lang-ca]` and both in `excludes` in `project.yml`; `verify-odr-packs.sh` extended to `(fr de es-ES ca ko nah)`; `just geo-packs-check` passes (packs up to date). `ca` not bundled.
5. **Progress isolation.** `testProgressIsolationForCatalan` (`.ca` vs `.esES`) confirms isolated tracks with shared factID/day coexistence.
6. **Catalog/enum invariants.** Catalog order matches `AppLocale.allCases`; one descriptor per case (generic invariant test added); count assertions bumped (`allCasesCount → 8`, catalog `6 → 8`).

### Runtime reachability
The `.ca` geo pack is actually built and installed via the existing `BundledLanguagePackProvider.buildPacks` (now includes `.esES, .ca`), and `GeoModel+PackData` resolves `.ca`/`.esES` columns for all four geo models — the feature is reachable in the running app, not just in tests.

Verdict: **APPROVED**. The formal code-owner review state is submitted separately by the code-owner-review agent.
