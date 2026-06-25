## Goal

Establish the shared, dependency-free test infrastructure that every subsequent per-language
story plugs into, so each language story can assert its acceptance criteria without re-inventing
helpers and without conflicting edits to the same test bodies. This foundational story adds **no
new language** (`AppLocale.allCases.count` stays 6); it hardens the invariants that all future
languages will be validated against.

## Summary of changes

- **`HanahuacTests/LanguageCatalogTests.swift`** — catalog↔enum invariants now iterate
  `AppLocale.allCases` generically (no hardcoded language list) so they automatically cover any
  language added later:
  - every `AppLocale` case has exactly one `LanguageDescriptor`;
  - `LanguageCatalog.all` order matches `AppLocale.allCases`;
  - bundled base languages (`en`, `es-MX`) carry no ODR tags;
  - downloadable languages carry exactly `[lang-<code>]`.
- **Language completeness helper** — a reusable helper that, given an `AppLocale`, reports
  missing UI keys (vs `en.lproj`) and geo-coverage gaps (countries/capitals/rivers/mountains/seas
  vs the bundled source JSON), driven from the generated `<code>-geo.json` so it works for future
  packs. Exercised by at least one test on an existing language.
- **`HanahuacTests/PerLanguageProgressTests.swift`** — a reusable, locale-parameterized
  progress-isolation assertion helper (ReviewCard / DailyProgressSnapshot rows keyed by
  `language` rawValue) that later language stories call with their new locale.
- No changes to `PACK_LANGUAGES` / `SUFFIX_BY_CODE` in `scripts/generate-geo-packs.py`.

The helpers are kept minimal and additive so per-language stories only ADD a call/case, never
restructure these files (avoids cross-story merge conflicts).

## Test plan

- [ ] `just lint` passes
- [ ] `just test` passes
- [ ] `just geo-packs-check` passes
- [ ] `just verify-odr-packs` passes
- [ ] iOS/Catalyst build is green
- [ ] `AppLocale.allCases.count` is still 6 (no new language added)
- [ ] CI green on this PR
