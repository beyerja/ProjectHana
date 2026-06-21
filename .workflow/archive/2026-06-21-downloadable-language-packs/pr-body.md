## Goal

Deliver each app language's content (UI strings + geo-name translations) as Apple-hosted, code-signed On-Demand Resource (ODR) packs instead of bundling every language into the main binary, so installed size stays flat and new languages can later be added without inflating the app. This feature re-architects the **existing 6 languages** (en, fr, de, es-MX, ko, nah) onto the new mechanism — it does **not** add new languages.

## Acceptance criteria coverage

- [x] Non-base languages' content (per-language `.lproj` strings **and** geo-name/capital translations) is delivered via ODR, not compiled into the main binary.
- [x] English and es-MX stay bundled as the guaranteed offline fallback chain; the app launches and is fully usable with **zero** packs downloaded.
- [x] Selecting a not-yet-downloaded language triggers a lazy `NSBundleResourceRequest` download with visible progress and a failure/retry path; on success UI strings + geo names switch over.
- [x] A `LanguagePackProvider` seam sits behind the picker/resolver so the ODR implementation can later be swapped for a signed-CDN provider without touching call sites.
- [x] Available languages + metadata (code, native name, fallback chain) are data-driven (`LanguageCatalog`) rather than a hand-maintained `switch` in `AppLocale`.
- [x] `Country` geo-name resolution no longer depends on hardcoded per-language fields/`switch` arms (`nameFr`, `capitalKo`, …); localized names come from the active pack's data keyed by language code, falling back es-MX → en.
- [x] `L10n` string resolution consults downloaded ODR pack bundles in addition to bundled `.lproj`, preserving the existing fallback chain.
- [x] Safety: packs are **data-only** (strings + JSON), never executable; integrity/authenticity inherited from Apple's App Store code-signing of ODR; **no** custom network/crypto/signature-verification trust code introduced. Pack data is schema-validated before use; parse/validation failures degrade safely to the bundled fallback and never crash.
- [x] Existing tests pass against the new mechanism; new tests cover pack resolution, fallback when a pack is absent, and the download state machine.

## Constituent stories / PRs

This feature shipped in 6 squash-merged stories:

1. **001 — language catalog** (#112): data-driven `LanguageCatalog` replacing the per-language `AppLocale` switch.
2. **002 — pack-provider seam** (#116): `LanguagePackProvider` seam + `BundledLanguagePackProvider` + `GeoNamePackData` / loader / resolver.
3. **003 — resolve through provider** (#120): L10n + geo resolution routed through the active provider seam.
4. **004 — ODR download state machine** (#126): ODR download state machine + `NSBundleResourceRequest` provider + `LanguagePackBootstrap` composition root.
5. **005 — picker download UX** (#134): picker download progress / failure+retry / ready UX.
6. **006 — ODR packaging & CI** (#139): ODR pack packaging in `project.yml` (`lang-<code>` tags for fr/de/ko/nah), geo-pack generator, data-only / base-only verify scripts, async `odr-validation.yml`, `docs/odr-packaging.md`.

## Safety & CI design

- **Data-only packs.** Packs contain only strings + JSON — never executable code. Authenticity/integrity come from Apple's App Store ODR code-signing; this feature adds no custom signature/hash verification. The future signed-CDN path remains implementable behind the same `LanguagePackProvider` seam without refactoring call sites.
- **Graceful degradation.** Pack data is schema-validated before use; any parse/validation failure or download failure degrades to the bundled es-MX → en fallback chain and never crashes. The app is fully functional offline with zero packs.
- **Async CI.** Fast checks remain blocking on PRs. The slower/device-leaning ODR validation runs asynchronously (`odr-validation.yml` on schedule / push-to-main with tracked findings) and is **not** a per-PR gate, per project CI conventions.

## Test plan

- [x] Post-merge lint is green.
- [x] Post-merge test suite is green (AppLocale, L10n bundle resolution, localized geo name, per-language progress, language manager, plus new pack-resolution / absent-pack-fallback / download-state-machine tests).
- [x] origin/main merged into the feature branch (merge commit cb969a0); pbxproj regenerated and README conflict resolved.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
