<!-- independent-review -->
## Independent review — APPROVED (round 1)

Fresh, cold-context 4-eye review of the foundational cross-language test scaffolding via `/code-review` (medium effort). The diff is test-only plus a clean, regenerated `project.pbxproj`.

**Verdict: APPROVED** — no blocking findings.

### Acceptance criteria
- **AC#1 — generic catalog/enum invariants:** `LanguageCatalogTests` iterates `AppLocale.allCases` with no hardcoded list — one-descriptor-per-case, catalog order == `allCases`, bundled-base carry no ODR tags, downloadable carry exactly `["lang-<code>"]`. Future languages are covered automatically. ✓
- **AC#2 — reusable completeness helper:** `LanguageCompletenessSupport` reports missing UI keys (vs `en.lproj`) and geo-coverage gaps, driven off the active `LanguagePackProvider`/`GeoNamePackData`; exercised by `LanguageCompletenessSupportTests` on existing locales. ✓
- **AC#3 — locale-parameterized progress-isolation helper:** `assertProgressIsolated(_:_:)` added to `PerLanguageProgressTests`, exercised on `(.en, .ko)`. Per-language stories only ADD a call. ✓
- **AC#4 — no new language:** `testCatalogContainsExactlySixLanguages` keeps the count at 6; no enum/`PACK_LANGUAGES` change. ✓
- **AC#5 — checks/CI:** delegated to CI on this PR and the code-owner-review step.

### Notes (non-blocking)
- Both new files are wired into the test group **and** the test target's Sources phase with consistent file-ref UUIDs — the pbxproj regen is correct.
- Every production seam the helper references exists and matches signatures (`LanguagePackProviderHolder.active`, `geoNameData(for:)`, `L10n.bundle(for:)`, `ODRTestSupport.lprojBundle(for:)` which `throw`s `XCTSkip` → `try?` → nil, `GeoNamePackData.entries`). The project uses `Localizable.strings`, so `NSDictionary(contentsOf:)` is the right reader.
- In the simulator/CI host, downloadable-locale UI/geo gaps degrade to empty (ODR packs unmounted), so the downloadable-locale tests are intentionally weak there. This is the documented, intended `ODRTestSupport`-style degradation, not a defect — real pack content is validated by the separate ODR content tests.

The formal bot review state is submitted by the separate code-owner-review step, not here.
