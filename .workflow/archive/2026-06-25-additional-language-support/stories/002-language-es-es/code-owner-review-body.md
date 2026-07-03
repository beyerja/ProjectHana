## Code-owner review — APPROVED

Independent confirming pass (second eye) over the es-ES (Español de España) diff. I reviewed the change directly and reached my own verdict; I concur with the independent review and found no additional blocking issues.

### Acceptance criteria — independently verified
- **AC1 picker name:** descriptor displayName `Español (España)`; asserted by test.
- **AC2 distinct base code:** `case esES = "es-ES"`, separate from `esMX`.
- **AC3 device default unchanged:** `AppLocale.matching(_:)` keeps `if language == "es" { return .esMX }` (unchanged); the `es-ES` rawValue can never match a bare language code, so es-ES is never auto-selected. Regression test asserts `matching("es_ES") == .esMX` and `matching("es-ES") == .esMX`.
- **AC4 fallback chain:** `[.esES, .esMX, .en]`; `bundleCandidates(for: .esES) == ["es-ES", "es-MX", "en"]`.
- **AC5 complete content:** every country/capital/river/mountain/sea carries an `es_es` value; full UI key set; completeness tests pass.
- **AC6 ODR not bundled:** `es-ES.lproj` + `es-ES-geo.json` tagged `[lang-es-ES]`, in `knownAssetTags`, excluded from the base resource tree; verify-odr-packs / verify-base-only green.
- **AC7 progress isolation:** PerLanguageProgressTests covers `.esES`.
- **AC8 catalog/enum invariants:** one descriptor per case; es-ES ordered immediately after es-MX; `downloadablePack`.
- **AC9 CI:** `Build & Test`, `gitleaks`, `Lint (all languages)` all green on the head commit.

### Content quality
Real, professional peninsular Castilian UI strings, genuinely distinct from es-MX (guillemets «», "prueba" not "quiz", "Comprobar", "Hecho", "Ajustes", "aplicación"). Geo content uses RAE-standard exonyms; the seed-from-es-MX-with-documented-override approach (`scripts/seed-es-es-geo.py`, single `SA: Arabia Saudí` override) is sound since RAE exonyms are pan-Hispanic.

### Wiring (reachability)
End-to-end path confirmed in production code, not just tests: AppLocale case → catalog descriptor → `BundledLanguagePackProvider.buildPacks` includes `.esES` → `GeoModel+PackData` resolves `.esES → nameEsEs/capitalEsEs`. The picker iterates `allCases`, so es-ES surfaces automatically. No "implemented but never installed" gap.

**Verdict: APPROVED.**
