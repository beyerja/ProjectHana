# 004 — ODR download state machine + `NSBundleResourceRequest` provider

## Title
Add the On-Demand Resources provider: lazy `NSBundleResourceRequest` download behind the
`LanguagePackProvider` seam, with a download state machine (progress / success / failure / retry)

## Goal
Implement the concrete ODR variant of `LanguagePackProvider` that lazily downloads a
non-base language's pack via `NSBundleResourceRequest`, and the download state machine that
the picker UI (story 005) observes. Selecting a not-yet-downloaded language triggers the
download; on success the provider exposes the downloaded pack's resolved bundle + geo data so
the resolver (story 003) serves that language's UI strings and geo names.

Base languages (en, es-MX) stay bundled and are NEVER downloaded. Network/pack failures degrade
gracefully to the fallback chain and never crash.

## Background (current state)
- After stories 002/003, all resolution flows through `LanguagePackProvider`; only the bundled
  provider exists. The catalog (001) marks fr/de/ko/nah as downloadable.

## Acceptance Criteria
- [ ] Non-base languages' content (per-language `.lproj` UI strings AND that language's
      geo-name/capital translations) is delivered via On-Demand Resources, not compiled into the
      main app binary, using `NSBundleResourceRequest` keyed by ODR tag(s) per language.
- [ ] An observable download state machine models per-language pack state: not-requested →
      downloading (with fractional progress) → available, plus a failure state with a retry
      transition. State is exposed for the picker (story 005) to render.
- [ ] Selecting a not-yet-downloaded language triggers a lazy ODR download; on success the
      provider returns that pack's resolved bundle + geo data and the active resolution switches
      to that language. The `NSBundleResourceRequest` is retained for the pack's lifetime and
      released/ended appropriately.
- [ ] A download failure surfaces a failure state with a retry path; retry re-issues the
      request. A failed/absent pack degrades to the fallback chain (selected → es-MX for ko/nah
      → en) so the app stays usable.
- [ ] The ODR provider conforms to the same `LanguagePackProvider` seam with NO changes to
      resolver/picker call sites beyond observing the state machine.
- [ ] Safety: packs are DATA-ONLY; integrity/authenticity is inherited from Apple's App Store
      code-signing of ODR. NO custom network/crypto/signature/hash verification code is added.
      Pack data is schema-validated (story 002 loader) before use; validation failure degrades
      safely.
- [ ] App remains fully functional offline with zero packs downloaded (base languages bundled).
- [ ] New tests cover the download state machine transitions (request → progress → success;
      request → failure → retry) and fallback when a pack is absent, using a test seam/fake for
      `NSBundleResourceRequest` (no live network in unit tests).

## Out of Scope
- The picker progress/retry UI rendering (story 005) — this story exposes the state it renders.
- ODR build/packaging configuration and async device-only validation CI (story 006).
- The signed-CDN provider (seam is already compatible from story 002).
- Adding new languages.
