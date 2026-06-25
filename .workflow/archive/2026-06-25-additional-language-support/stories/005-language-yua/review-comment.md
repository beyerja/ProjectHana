<!-- independent-review -->
## Independent review — round 1 — ✅ APPROVED

Fresh cold-context 4-eye review of the Yucatec Maya (`yua`, "Màaya t'àan") downloadable-language pack. No blocking findings.

### Verified beyond "it compiles"
1. **Content is genuine Yucatec Maya, not Spanish/English/gibberish.** Spot-checked many keys: consistent INALI orthography — glottal stop as apostrophe (`jump'éel`, `lu'umo'ob`, `k'áak'náabo'ob`), `-o'ob` plural, tone-marked vowels (`Màaya t'àan`). Format specifiers (`%d`/`%@`) match the `en` counterparts in count and type.
2. **Fallback chain is `[.yua, .esMX, .en]`** — Mexican Spanish, not es-ES — in `LanguageCatalog`, in `AppLocale.fallsBackThroughSpanish`, and asserted by tests (`testYucatecBundleCandidatesRouteThroughMexicanSpanish` → `["yua", "es-MX", "en"]`).
3. **The gap key is a real fallback.** `settings.sync.toggle` is genuinely absent from `yua.lproj` (only a NOTE comment) and present in `es-MX` (`Sincronización con iCloud`) and `en`. `testYucatecGapKey_resolvesToMexicanSpanishBeforeEnglish` exercises yua → es-MX before en.
4. **Geo JSON `yua` columns are plausible best-effort**, not Spanish copies: distinct Maya names where they exist (`K'áak'náab Atlántiko`, `U Móol K'áak'náabil Mejiko`, `Noj Lu'umil Amerika`, `Puksó'ob Rocosas`), phonetic Maya respellings of loanword toponyms (`Mejiko`, `Kanada`), omitted where no endonym exists. `name_yua`/`capital_yua` decode via `convertFromSnakeCase`; all four geo models list `.yua` exhaustively.
5. **ODR wiring correct.** `yua.lproj` + `yua-geo.json` tagged `[lang-yua]`, added to `excludes`, declared on-demand; pbxproj regenerated. `es-MX`/`en` stay untagged bundled base. `AppLocale.matching` maps es-* → `.esMX` before the catalog code-lookup, so adding `yua` does not perturb Spanish (guarded by `testMatchingYucatecMayaDoesNotPerturbSpanish`). Per-language progress isolation test for `.yua` vs `.esMX` present.
6. **Scratch script correctly not committed.** No `scripts/add-yua-geo.py` is tracked or in the working tree; curated data lives in the JSON, and `just geo-packs-check` confirms `yua-geo.json` is up to date with source.

### Gates re-run locally
`just geo-packs-check` PASS · `just verify-odr-packs` PASS (yua data-only, tag contract intact) · catalog count 9→10 and ordering/odrTags/availability tests updated.

### Non-blocking nit (1 inline comment)
The downloadable-language set is hand-maintained in three lists (`packLanguages` in `BundledLanguagePackProvider`, `PACK_LANGUAGES` in `generate-geo-packs.py`, `LANG_CODES` in `verify-odr-packs.sh`). Pre-existing pattern, not introduced here; CI gates catch drift; this change correctly follows the ca/eu precedent. Could later be catalog-derived. Does not block.

**Verdict: APPROVED.** The formal code-owner review is submitted separately by the `code-owner-review` agent.
