<!-- code-owner-review -->
## Code-owner review — APPROVED

Independent confirming pass on story 009 (Serbian Cyrillic `sr`, COMPLETE-content downloadable/ODR language). Reviewed the diff directly as a fresh, cold-context reviewer — I did not author this change — and formed my own verdict rather than rubber-stamping the first reviewer.

### Independently verified
- **Wiring (no orphaned seams)**: `AppLocale.case sr`; catalog descriptor `displayName "Српски"`, `fallbackChain [.sr, .en]`, `availability .downloadablePack`, `odrTags [lang-sr]`, ordered between nl and ko with the Cyrillic script-decision comment. Picker/resolver are driven by `AppLocale.allCases` + `LanguageCatalog` (both now contain `sr`); `GeoModel+PackData` handles `case .sr` in all 5 raw-name switches; Country/River/MountainRange/Sea carry `nameSr`/`capitalSr`.
- **COMPLETE content + ODR**: 156/156 UI keys, full geo coverage, `sr-geo.json` generated; `sr.lproj` + `sr-geo.json` tagged `[lang-sr]` and excluded from the base bundle — `sr` is not bundled.
- **No regression**: `matching(_:)` es-* → es-MX mapping unperturbed (asserted); `fallsBackThroughSpanish == false` (asserted); per-language progress isolation test for `.sr` present; catalog/enum invariants updated 13→14.
- **Round-1 nit fixed**: stale `...Thirteen` test name renamed to `...Fourteen`.
- **CI green** on head `c9f2c771`: Build & Test, Lint (all languages), gitleaks, detect-changes all pass.

No blocking findings. Formal review state submitted as `Hanahuac-Bot` (APPROVED), confirmed via read-back.

Verdict: **APPROVED**.
