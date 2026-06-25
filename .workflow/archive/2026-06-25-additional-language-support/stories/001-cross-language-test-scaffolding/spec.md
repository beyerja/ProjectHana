# 001 — Cross-language test scaffolding & catalog invariants

## Title
Shared cross-language test scaffolding and catalog/enum invariants (foundational)

## Goal
Establish the small, shared test infrastructure that every subsequent per-language story
plugs into, so each language story can assert its acceptance criteria without re-inventing
helpers and without conflicting edits to the same test bodies. This story adds NO new
language; it hardens the invariants that all 8 new languages will be validated against and
provides reusable helpers for completeness/fallback/progress-isolation checks.

This is the leading story by design: the helpers and parameterizable invariant tests it adds
are referenced (extended with new cases) by stories 002–009. It must compile and pass on its
own with only the 6 existing languages present.

## Files to change
- `HanahuacTests/LanguageCatalogTests.swift` — strengthen/confirm catalog↔enum invariants so
  they iterate `AppLocale.allCases` generically (every case has exactly one descriptor; catalog
  order matches `AppLocale.allCases`; bundled base languages carry no ODR tags; downloadable
  languages carry exactly `[lang-<code>]`). These assertions must already pass for the 6
  existing languages and must automatically cover any language added later.
- `HanahuacTests/ODRTestSupport.swift` (or a new `HanahuacTests/LanguageCompletenessSupport.swift`)
  — add a reusable helper that, given an `AppLocale`, reports missing UI keys (vs `en.lproj`)
  and geo-coverage gaps (countries/capitals/rivers/mountains/seas vs the bundled source JSON).
  Drive it from the generated `<code>-geo.json` / source columns so it works for future packs.
- `HanahuacTests/PerLanguageProgressTests.swift` — add a reusable, locale-parameterized
  progress-isolation assertion helper (ReviewCard / DailyProgressSnapshot rows keyed by
  `language` rawValue) that later language stories call with their new locale.
- `scripts/generate-geo-packs.py` — NO new language here, but confirm `--check` passes; do not
  modify `PACK_LANGUAGES`/`SUFFIX_BY_CODE` in this story.

## Acceptance Criteria
1. Catalog/enum invariants are expressed generically over `AppLocale.allCases` (not a hardcoded
   list), so they will cover the 8 future languages automatically:
   - every `AppLocale` case has exactly one `LanguageDescriptor`;
   - `LanguageCatalog.all` order matches `AppLocale.allCases`;
   - bundled base languages (`en`, `es-MX`) carry no ODR tags;
   - downloadable languages carry exactly `[lang-<code>]`.
2. A reusable completeness helper exists that returns the set of missing UI keys (relative to
   `en.lproj`) and the set of geo entities lacking a name/capital for a given locale; it is
   covered by at least one test exercising it on an existing language.
3. A reusable, locale-parameterized progress-isolation helper exists, exercised by an existing
   locale, asserting ReviewCard / DailyProgressSnapshot rows do not bleed across locales.
4. No new language is added in this story; `AppLocale.allCases` count is still 6.
5. `just lint`, `just test`, `just geo-packs-check`, and `just verify-odr-packs` pass; an
   iOS/Catalyst build is green. CI green on the PR.

## Notes
- Keep the helpers minimal and dependency-free so the per-language stories only ADD a call/case,
  never restructure these files (avoids cross-story merge conflicts).
- Do NOT touch workflow tooling or add agent files.
