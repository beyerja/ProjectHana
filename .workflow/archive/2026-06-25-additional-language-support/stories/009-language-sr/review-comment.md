<!-- independent-review -->
## Independent review — Round 1: APPROVED

Story 009 adds Serbian (Cyrillic, `sr`) as a COMPLETE-content downloadable (ODR) language. I reviewed the diff as an independent, cold-context reviewer (did not author this change) and verified every acceptance criterion at runtime, not just that it compiles.

### Verified
- **UI completeness**: `sr.lproj/Localizable.strings` has 156/156 keys, zero missing vs `en.lproj` (`comm` diff empty). `just l10n-check` PASSES with `sr` enforced at full coverage and no untranslated-English warnings. Spot-checked values are genuine professional Serbian Cyrillic (Подешавања, Прикажи напредак, Један свет…), not MT stubs or English leakage.
- **Geo completeness, all Cyrillic**: 197/197 `name_sr` + `capital_sr` in countries.json; 32 rivers, 23 mountains, 20 seas — zero missing, zero non-Cyrillic alpha values. Genuine exonyms confirmed: Немачка/Берлин, Шпанија/Мадрид, Москва, Београд, Дунав, Алпи.
- **ODR pack**: `sr-geo.json` = 272 entries (197+32+23+20), all-Cyrillic, valid + up to date. `just verify-odr-packs` PASSES (`lang-sr → sr.lproj + sr-geo.json`, data-only, base langs untagged). project.yml excludes both from the base bundle AND tags `[lang-sr]` — sr is NOT bundled.
- **Catalog/enum**: descriptor `displayName "Српски"`, `fallbackChain [.sr, .en]`, `availability .downloadablePack`, `odrTags [lang-sr]`; script-decision comment present. `fallsBackThroughSpanish == false` (tested). es-MX device-locale default and the es-* `matching(_:)` mapping are untouched (regression tests assert es-* → es-MX still holds).
- **Models/switches**: River/MountainRange/Sea gained `nameSr`; Country already had `name_sr`/`capital_sr`; GeoModel+PackData has `case .sr` in all 5 raw-name switches.
- **Tests**: catalog count 13→14 and `allCases.count == 14` updated; per-language progress isolation `testProgressIsolationForSerbian(.sr, .en)` present.
- **Seed script**: `scripts/seed-sr-geo.py` is durable/idempotent (drops + re-inserts the sr column after name_nl, fails loudly on any missing id), matching the seed-nl-geo.py precedent. Acceptable to commit.
- **CI**: all checks green (Build & Test, Lint all languages, gitleaks, detect-changes).

### Findings
- 1 non-blocking nit (inline): `testCatalogContainsExactlyThirteenLanguages` correctly asserts `== 14` but its name still says "Thirteen" — cosmetic, rename suggested.

No blocking findings. Verdict: **APPROVED**.
