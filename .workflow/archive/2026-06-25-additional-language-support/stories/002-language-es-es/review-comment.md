<!-- independent-review -->
## Independent review — APPROVED

Cold-context 4-eye review of the es-ES (Español de España) story. No blocking findings.

### Critical content-quality requirements — all verified
- **Real, professional Castilian Spanish UI strings, distinct from es-MX where Peninsular differs.** Spot-checked: `home.tagline` "una prueba a la vez" vs es-MX "un quiz a la vez" (avoids the anglicism); quiz terminology consistently "Prueba …" vs Mexican "Quiz …"; «» guillemets; `learn.done` "Hecho" vs "Listo"; `capital_quiz.check` "Comprobar" vs "Verificar"; "aplicación" vs "app". Genuine peninsular usage, not a copy and not machine output.
- **Real, professional geo content (RAE-standard exonyms).** Spot-checked countries/capitals/rivers/mountains/seas: Pekín, Misisipi, Yangtsé, Yeniséi, Karakórum, Éufrates, Dniéper, Arabia Saudí. Correct professional Spanish, not garbage.
- **Complete content (no gaps).** `LanguageCompletenessSupportTests` asserts zero missing UI keys vs English base and full geo coverage (every country/capital/river/mountain/sea) for `.esES`; both pass.
- **Downloadable via ODR, NOT bundled.** `es-ES.lproj` + `es-ES-geo.json` tagged `[lang-es-ES]`, excluded from the main resource tree, re-added as ODR-tagged sources. `just verify-odr-packs` and `just verify-base-only` confirm data-only + es-ES not bundled.
- **es-MX remains the device-locale default; es-ES never auto-selected.** `AppLocale.matching(_:)` `es`→`.esMX` is unchanged; the es-ES rawValue ("es-ES") can never match a bare languageCode. Regression test asserts `matching("es_ES") == .esMX`.
- **Per-language progress isolation.** `assertProgressIsolated(.esES, .esMX)` passes (distinct tracks; shared factID coexists).
- **Catalog/enum invariants.** One descriptor per case, order matches `allCases`, generic ODR-tag contract; es-ES is `downloadablePack` with `[lang-es-ES]`.

### Production wiring (AC reachability)
End-to-end path confirmed: AppLocale case → catalog descriptor → `BundledLanguagePackProvider.buildPacks` now includes `.esES` → `GeoModel+PackData` resolves `.esES → nameEsEs/capitalEsEs`. The picker iterates `allCases`, so es-ES surfaces automatically. No "implemented but never installed" gap.

### Checks
`just lint`, full `xcodebuild test` (TEST SUCCEEDED), `just geo-packs-check`, `just verify-odr-packs`, `just verify-base-only` (Catalyst build SUCCEEDED) all pass locally; CI green on the PR.

### Non-blocking observation (not blocking)
The es-ES geo columns are seeded from the es-MX RAE exonyms with a single documented Peninsular override (`SA: Arabia Saudí`). This is defensible — RAE exonyms are pan-Hispanic and the values verified as correct professional Spanish — and the documented rationale (`scripts/seed-es-es-geo.py`) is sound. If future curation surfaces additional genuine Spain-vs-Mexico divergences, extend the override maps; no action required for this story.

**Verdict: APPROVED.** Formal code-owner submission is performed by the separate code-owner-review step.
