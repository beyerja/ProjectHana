<!-- independent-review -->
## Independent review — APPROVED (round 1)

Fresh, cold-context 4-eye review of the Dutch (`nl`) complete-content language addition. No blocking findings.

### Translation quality & completeness (load-bearing) — PASS
- **UI strings** (`nl.lproj/Localizable.strings`): exactly **156 keys**, zero missing vs `en.lproj` (verified by `just l10n-check`). Values are genuine, idiomatic native Dutch — no English left in place, no machine word-salad. Spot-checks: `home.tagline` = "Eén wereld, één quiz per keer", `home.tile.all_done` = "Helemaal bij", `quiz.mode.type_capital.title` = "Typ de hoofdstad". Plurals/articles correct (Categorieën, Rivieren, Bergen, Zeeën). All `%@`/`%d` format specifiers preserved. Dutch decimal comma used correctly ("EF ≥ 2,0"); en-dash ranges ("Herh. 1–2").
- **Geo content**: every entity has an `nl` value — **197** countries (name + capital), **32** rivers, **23** mountains, **20** seas = **272** pack entries. Exonyms verified correct: Duitsland/Berlijn, Spanje/Madrid, Italië/Rome, Rusland/Moskou, Verenigd Koninkrijk/Londen, China/Peking, Middellandse Zee, Alpen, Pyreneeën, Rijn, Donau, Grote Oceaan, Noordelijke IJszee, Warschau, Kopenhagen, Wenen, Boekarest. No English left in place; no wrong exonyms found.

### Precedent conformance vs it (#162) / pl (#164) — PASS
- Catalog: `displayName` "Nederlands", `fallbackChain [.nl, .en]` (straight to en, no Spanish hop), `availability .downloadablePack`, `odrTags [lang-nl]`; ordering matches `AppLocale.allCases` (nl immediately after pl, before ko).
- `project.yml`: `nl.lproj` + `Resources/nl-geo.json` in `excludes` AND tagged `[lang-nl]` resources (not bundled).
- `es-MX` device-default selection untouched — `matching()` es-* → es-MX mapping verified unperturbed; `nl` auto-detects via catalog code-lookup.
- `nl` added to `FULL_LOCALES` in `check-l10n-completeness.py`; catalog count 12→13.
- Durable `scripts/seed-nl-geo.py` present (matches seed-it / seed-pl / seed-es-es pattern); no one-shot scratch scripts left behind; working tree clean.

### Correctness — PASS
- `GeoModel+PackData.swift`: `.nl` arms present in all four extensions (Country name + capital, River, MountainRange, Sea); `Country` model has `nameNl`/`capitalNl`.
- Tests updated: counts 12→13 (`AppLocaleTests`, `LanguageCatalogTests`), nl resolution (`testDutchBundleCandidatesGoStraightToEnglish`, `testMatchingDutchDoesNotPerturbSpanish`), per-language progress isolation (`testProgressIsolationForDutch`), ordering invariant.

### Gates run locally — all green
`just l10n-check`, `just geo-packs-check`, `just verify-odr-packs` all PASS.

Note (non-blocking, informational): `a11y.state.incorrect` = "onjuiste antwoord" uses the inflected adjective form (consistent with `a11y.state.correct` = "juiste antwoord"); reads naturally as a VoiceOver announcement. Not a defect.

**Verdict: APPROVED.** The formal code-owner review state is submitted separately by the code-owner-review agent.
