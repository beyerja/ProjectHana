<!-- code-owner-review -->
## Code-owner review — APPROVED

Independent confirming pass (second eye) over PR #154 (es-ES, Español de España). Reviewed the diff directly and reached my own verdict; I concur with the independent review and found no additional blocking issues.

- AC1–AC9 independently verified (picker name `Español (España)`; distinct base code; device default unchanged — `matching("es_ES") == .esMX`, es-ES never auto-selected; fallback `[es-ES, es-MX, en]`; complete UI + geo content; ODR-tagged `[lang-es-ES]` and not bundled; per-language progress isolated; catalog order es-ES immediately after es-MX).
- Real peninsular Castilian UI (guillemets «», "prueba"/"Comprobar"/"Hecho"/"Ajustes"), RAE-standard geo content via documented seed-from-es-MX + override.
- Production wiring traced end-to-end (AppLocale → catalog → `BundledLanguagePackProvider.buildPacks` includes `.esES` → `GeoModel+PackData`); picker iterates `allCases`.
- CI green on head: `Build & Test`, `gitleaks`, `Lint (all languages)`.

Formal review state **APPROVED** submitted as `Hanahuac-Bot` through the wrapper and confirmed via read-back. Merge gate satisfied.
