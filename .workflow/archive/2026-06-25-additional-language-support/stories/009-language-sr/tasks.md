# Tasks — 009 Language: Српски / Serbian (Cyrillic) (sr)

## Authoritative targets (confirmed from codebase, bake into implementation)
- **UI key count: 156** — `sr.lproj/Localizable.strings` MUST contain exactly the 156 canonical
  keys present in `en.lproj` (verified: en, it, pl, nl all = 156 `=` lines). The spec text "~85" is
  STALE; 156 is authoritative. Zero missing keys (completeness check is enforced for FULL locales).
- **Countries: 197** — every country in `Hanahuac/Resources/countries.json` needs BOTH `name_sr`
  AND `capital_sr` (Cyrillic). 197 names + 197 capitals, zero gaps.
- **Rivers: 32** — every river in `rivers.json` needs `name_sr`.
- **Mountains: 23** — every mountain in `mountains.json` needs `name_sr`.
- **Seas: 20** — every sea in `seas.json` needs `name_sr`.
- **Catalog/enum count: 13 → 14** — `LanguageCatalog.all.count` and `AppLocale.allCases.count`
  both currently assert `13`; bump to `14`.
- **Locale code:** `sr` (rawValue == display-name-independent code). **Display name:** `Српски`.
- **Script:** CYRILLIC (constitutionally designated official script of Serbian). Document the
  script-choice rationale in a code comment at the descriptor.
- **Ordering:** insert `sr` AFTER `nl`, BEFORE `ko` in both `AppLocale` and `LanguageCatalog.all`
  (matching the FULL-language precedent it→pl→nl). This shifts ko/nah ordering assertions.
- **FULL-content language:** fallback chain `[.sr, .en]` (straight to English safety net, NOT
  through es-MX/es-ES). `fallsBackThroughSpanish` must be `false` for `.sr`.
- **es-MX stays device-locale default:** do NOT touch the `es-*` → `.esMX` mapping or default
  selection in `matching(_:)`. `sr` auto-detects only via the generic catalog code-lookup
  (code `sr` == rawValue), which requires no `matching(_:)` edit.

## Tasks
- [ ] 001: Add `case sr` to `Hanahuac/L10n/AppLocale.swift` immediately after `case nl` (before
  `case ko`). Update the doc comments in `matching(_:)` to mention `sr` auto-detects via the catalog
  code-lookup; make NO change to the `es-*` mapping or the `return .en` default.
- [ ] 002: Add the `sr` `LanguageDescriptor` to `Hanahuac/L10n/LanguageCatalog.swift` immediately
  after the `nl` entry (before `ko`): `code: AppLocale.sr.rawValue`, `displayName: "Српски"`,
  `fallbackChain: [.sr, .en]`, `availability: .downloadablePack` (odrTags defaults to `[lang-sr]`).
  Add a code comment documenting (a) it is a COMPLETE-content language routing straight to English,
  and (b) the Cyrillic-script decision rationale (official constitutionally designated script;
  authoritative geographic names best served by the official script — feature spec §5). Update the
  `LanguageCatalog.all` header comment language list to include `sr`.
- [ ] 003: Create `Hanahuac/sr.lproj/Localizable.strings` — COMPLETE professional Serbian Cyrillic
  for ALL 156 canonical keys from `en.lproj` (exact key set, zero missing). All values in Cyrillic
  except legitimately-shared tokens (Apple brand `iCloud`, the `%d / 3` `learn_map.streak` format
  string, format specifiers). Mirror the structure/section comments of `nl.lproj`/`pl.lproj`.
- [ ] 004: Create durable idempotent `scripts/seed-sr-geo.py` modeled on `scripts/seed-nl-geo.py`
  (NOT a one-shot scratch script): `COUNTRY_NAME_SR` (197), `COUNTRY_CAPITAL_SR` (197),
  `RIVER_NAME_SR` (32), `MOUNTAIN_NAME_SR` (23), `SEA_NAME_SR` (20) — all Cyrillic, keyed by entity
  id, zero gaps (FAIL on any missing). Insert `name_sr` after `name_nl` and `capital_sr` after
  `capital_nl` via the `_insert_after` anchor pattern. Re-running re-seeds cleanly (idempotent).
- [ ] 005: Run `python3 scripts/seed-sr-geo.py` to populate `name_sr`/`capital_sr` into
  `countries.json`, `rivers.json`, `mountains.json`, `seas.json`. Confirm 197+197+32+23+20 columns
  added with no `FAIL` output.
- [ ] 006: Add `"sr"` to `PACK_LANGUAGES` and `"sr": "sr"` to `SUFFIX_BY_CODE` in
  `scripts/generate-geo-packs.py` (place after `nl`, before `ko` for consistency). Update the module
  docstring language list to include `sr`.
- [ ] 007: Generate `Hanahuac/Resources/sr-geo.json` via `just geo-packs`; verify it has 272
  entries (197 countries + 32 + 23 + 20) and confirm `just geo-packs-check` passes.
- [ ] 008: Add `"sr"` to `FULL_LOCALES` in `scripts/check-l10n-completeness.py` (after `nl`). Add any
  legitimately-identical-to-English `(sr, key)` entries to `IDENTICAL_VALUE_ALLOWLIST` ONLY if the
  Cyrillic value is genuinely byte-identical to English (e.g. `settings.section.icloud` "iCloud",
  `learn_map.streak` "%d / 3"); keep the list minimal and justified. Update the module docstring
  (lines describing FULL locales) to mention `sr`.
- [ ] 009: Update `project.yml`: add `sr.lproj` and `Resources/sr-geo.json` to the `excludes` list
  (after the `nl` entries), and add the two ODR folder/file resource references tagged
  `[lang-sr]` (after the `nl` block, before `ko`). Update the excludes-section comment counts/lists.
  Regenerate the Xcode project via `just generate`.
- [ ] 010: Update `HanahuacTests/LanguageCatalogTests.swift`: bump `LanguageCatalog.all.count`
  assertion `13 → 14`; add `displayName` assertion `.sr == "Српски"`; add fallback-chain assertion
  `.sr == [.sr, .en]` plus `AppLocale.sr.fallsBackThroughSpanish == false` (COMPLETE content, must
  not route through Spanish); add `.sr` to the downloadable-pack list (`testDownloadablePackLanguages`)
  and add `AppLocale.sr.odrTags == ["lang-sr"]`.
- [ ] 011: Update `HanahuacTests/AppLocaleTests.swift`: bump `AppLocale.allCases.count` `13 → 14`;
  add `AppLocale.matching(Locale(identifier: "sr"|"sr-RS"|"sr_RS")) == .sr`; add `AppLocale.sr.id`,
  `displayName "Српски"`, `L10n.bundleCandidates(for: .sr) == ["sr", "en"]`; add an ordering test
  asserting `sr` immediately follows `nl` and immediately precedes `ko`, and FIX the existing
  nl/ko ordering assertion (`koIndex == nlIndex + 1` becomes `srIndex == nlIndex + 1` and
  `koIndex == srIndex + 1`).
- [ ] 012: Update `HanahuacTests/LanguagePickerViewModelTests.swift` if it enumerates the full
  locale set or asserts a row count — add the `sr`/"Српски" row where the existing FULL languages are
  covered (grep for `nl`/`Nederlands`/`Polski` patterns; mirror them for `sr`).
- [ ] 013: Add a per-language progress isolation test for `.sr` in
  `HanahuacTests/PerLanguageProgressTests.swift`: `func testProgressIsolationForSerbian()` calling
  `assertProgressIsolated(.sr, .en)`, mirroring `testProgressIsolationForDutch`. The
  `testSummaryAllCoversEveryLocaleWithZerosForEmpty` test auto-covers `.sr` via `allCases.count`.
- [ ] 014: Run the full gate locally: `just lint` (includes `l10n-check`), `just test`,
  `just geo-packs-check`, `just verify-odr-packs`, and an iOS/Catalyst build. Confirm `sr` is NOT
  bundled (excluded; ODR-only), completeness passes (zero missing UI keys, full geo coverage), and
  all catalog/enum invariants hold.
