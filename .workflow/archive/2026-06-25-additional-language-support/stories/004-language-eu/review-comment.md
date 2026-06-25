<!-- independent-review -->
## Independent review — APPROVED (round 1)

Deep `/code-review` pass (high effort) + story-contract enforcement. No blocking findings; no inline comments needed.

**Verdict: APPROVED.**

### Contract checks (story 004 — Basque `eu`)
- **Authentic Basque (not MT, not copied Spanish):** UI strings and geo values are genuine professional Euskara — `Herrialdeak`/`Ibaiak`/`Mendiak`/`Itsasoak`/`Ezarpenak`/`Hizkuntza`, correct ergative/genitive grammar (`%@(r)en`, `-k`), `«»` quotes. Geo exonyms distinct from Spanish where Basque differs (`Espainia`, `Frantzia`, `Grezia`, `Hegoafrika`, `Herbehereak`, `Erresuma Batua`, `Boli Kosta`, `Ozeano Barea`, `Ibai Horia`). Values that coincide with Spanish (e.g. `Madrid`, `Atenas`, `Angola`) are legitimate Basque-equals-Spanish forms, not copy errors.
- **Fallback chain `[eu, es-ES, en]` through Spanish:** `LanguageCatalog` descriptor + `bundleCandidates(for: .eu) == ["eu","es-ES","en"]`. The deliberately-omitted gap key `settings.sync.toggle` (documented inline in `eu.lproj`) is genuinely absent from eu and present in es-ES. `testBasqueGapKey_resolvesToSpainSpanishBeforeEnglish` asserts the gap resolves to the **es-ES value AND not English** — the chain order through Spanish is truly tested.
- **ODR, tagged `[lang-eu]`, NOT bundled:** `project.yml` lists `eu.lproj` + `Resources/eu-geo.json` in both resources (`resourceTags: [lang-eu]`) and `excludes`; en/es-MX remain the only bundled bases. `odrTags` defaults to `["lang-eu]` for `.downloadablePack`. `verify-odr-packs.sh` LANG_CODES updated. `just geo-packs-check` passes (eu-geo.json up to date).
- **es-MX stays device-locale default:** `matching(_:)` unchanged for `es-*`; `testMatchingBasqueDoesNotPerturbSpanish` asserts `es_ES`/`es-ES` → `.esMX` while `eu`/`eu-ES` auto-detect `.eu` via catalog code-lookup. No es-ES added to device matching.
- **Per-language progress isolation:** `testProgressIsolationForBasque` covers `.eu` vs `.esES`.
- **Catalog/enum invariants:** one descriptor per case, catalog order matches `AppLocale.allCases` (eu immediately after ca), bundled bases carry no ODR tags, downloadables carry `["lang-<code>"]` — all generically tested. Count assertions updated 8→9.

### Code-review engine
Correctness angles (line-by-line, removed-behavior, cross-file tracer) and cleanup/altitude/conventions: no findings. All `.eu` switch arms in `GeoModel+PackData.swift` reference `nameEu`/`capitalEu` correctly (no copy-paste). Model `Codable` additions are optional-with-default (existing JSON still decodes). Country coverage 197/197; rivers/mountains/seas best-effort (permitted for eu) with safe fallback.

The formal code-owner review state is submitted by the separate `code-owner-review` agent.
