## Code-owner review — APPROVED

Independent second-eye re-verification of the Yucatec Maya (`yua`, "Màaya t'àan") downloadable-language pack. I read the full diff directly (not via the review skill) and reached my own verdict; the `independent-review` findings were input, not my conclusion.

Independently confirmed:

1. **Genuine Yucatec Maya, not copied Spanish/English.** The `yua.lproj` strings use consistent INALI orthography — glottal apostrophe (`Jump'éel`, `lu'umo'ob`, `K'áak'náabo'ob`, `Puksó'obo'ob`), `-o'ob` plurals, tone-marked `Màaya t'àan`. Format specifiers (`%d`/`%@`) match the `en` counterparts.
2. **Fallback chain is es-MX (not es-ES).** `LanguageCatalog` descriptor `fallbackChain: [.yua, .esMX, .en]`; `fallsBackThroughSpanish` true; tests assert `["yua", "es-MX", "en"]`. Distinct from ca/eu's es-ES route.
3. **Gap key is a real omission.** `settings.sync.toggle` is genuinely absent from `yua.lproj` (NOTE only), present in es-MX/en, and exercised by `testYucatecGapKey_resolvesToMexicanSpanishBeforeEnglish` (yua → es-MX before en).
4. **ODR wiring excludes yua from the base bundle.** `project.yml` adds `yua.lproj` + `Resources/yua-geo.json` to `excludes` and re-declares them `resourceTags: [lang-yua]`; pbxproj `ASSET_TAGS = ("lang-yua")`; `verify-odr-packs.sh` LANG_CODES includes `yua`; es-MX/en stay untagged/bundled.
5. **No scratch script committed.** Only the established `scripts/generate-geo-packs.py` is modified; no `add-yua-geo.py` is tracked.

Wiring is complete and reachable end-to-end: `AppLocale.yua`, the `GeoModel+PackData` switches, the model `nameYua`/`capitalYua` fields, and `BundledLanguagePackProvider.packLanguages` all route to production call sites — the acceptance criteria are reachable at runtime, not just under test. CI green on the head (Build & Test, gitleaks both success). `yua` is fallback-permitted, so incomplete content is acceptable by design.

Non-blocking nit (agreed, does not block): the downloadable-language set is hand-maintained in three lists (`packLanguages`, `PACK_LANGUAGES`, `LANG_CODES`); pre-existing pattern, CI gates catch drift.

Verdict: **APPROVED.**
