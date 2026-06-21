# Feature: Downloadable language packs via On-Demand Resources

## Goal
Deliver each app language's content (UI strings + geo-name translations) as Apple-hosted, code-signed On-Demand Resource (ODR) packs instead of bundling every language in the main binary, so installed size stays flat and (in a later feature) new languages can be added without inflating the app. This feature re-architects the EXISTING 6 languages (en, fr, de, es-MX, ko, nah) onto the new mechanism; it does NOT add new languages.

## Acceptance Criteria
- [ ] Non-base languages' content (the per-language `.lproj` UI strings AND that language's geo-name/capital translations) is delivered via On-Demand Resources, not compiled into the main app binary.
- [ ] English and es-MX remain bundled in the binary as the guaranteed offline fallback chain; the app launches and is fully usable with ZERO packs downloaded.
- [ ] Selecting a not-yet-downloaded language in the language picker triggers a lazy ODR download (NSBundleResourceRequest) with visible progress and a failure/retry path; on success the UI strings and geo names switch to that language.
- [ ] A `LanguagePackProvider` (or equivalently named) abstraction sits behind the picker/resolver so the ODR implementation can later be swapped for a signed-CDN provider WITHOUT touching call sites.
- [ ] The list of available languages plus their metadata (code, native display name, fallback chain) is data-driven rather than a hand-maintained per-language `switch` in `AppLocale`, to the extent feasible without adding languages.
- [ ] `Country` geo-name resolution no longer depends on hardcoded per-language struct fields + `switch` arms (`nameFr`, `capitalKo`, …); localized names come from the active language's pack data keyed by language code, falling back through es-MX → en.
- [ ] `L10n` string resolution consults downloaded ODR pack bundles in addition to / instead of bundled `.lproj`, preserving the existing fallback chain (selected → es-MX for ko/nah → en).
- [ ] Safety: packs are DATA-ONLY (strings + JSON), never executable; integrity/authenticity is inherited from Apple's App Store code-signing of ODR; NO custom network/crypto/signature-verification trust code is introduced in this feature. Pack data is schema-validated before use and a parse/validation failure degrades safely to the bundled fallback, never crashes.
- [ ] Existing tests (AppLocale, L10n bundle resolution, localized geo name, per-language progress, language manager) pass against the new mechanism; new tests cover pack resolution, fallback when a pack is absent, and the download state machine.

## Constraints
- iOS 17.0 deployment target. On-Demand Resources (NSBundleResourceRequest) is the concrete mechanism — Managed Background Assets requires iOS 18 and is NOT used.
- Apple hosts and code-signs ODR packs; NO self-hosted server and NO custom signature/hash verification in this feature.
- Pack versioning is tied to the app release (ODR tags built per app version); already-installed packs refresh on app update. No independent OTA pack updates in this feature.
- Must remain fully functional offline once base languages are bundled; network/pack failures degrade gracefully to the fallback chain and never crash.
- The provider abstraction must keep the FUTURE signed-CDN path (Ed25519 + SHA-256 + pinned public key + ATS + zip-slip-safe extraction) implementable later without refactoring call sites — but do not implement it now.
- Per project CI conventions: keep fast checks blocking on PRs; any slow or device-only ODR validation runs async (scheduled / push-to-main with tracked findings), not per-PR.

## Out of Scope
- Adding any new languages beyond the existing 6.
- Translation authoring / pipeline / tooling.
- The signed-CDN provider implementation itself (only the seam for it).
- OTA pack updates independent of app releases.
