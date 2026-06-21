## Goal

Implement the concrete On-Demand Resources (ODR) variant of `LanguagePackProvider` that lazily
downloads a non-base language's pack via `NSBundleResourceRequest`, plus the observable download
state machine the picker UI (story 005) will render. Selecting a not-yet-downloaded language
triggers the download; on success the provider exposes the downloaded pack's resolved bundle and
geo data so the resolver (story 003) serves that language's UI strings and geo names. Base
languages (en, es-MX) stay bundled and are never downloaded; network/pack failures degrade
gracefully to the fallback chain and never crash.

## Summary of changes

- **`ResourceRequesting` test seam** wrapping `NSBundleResourceRequest`: minimal surface
  (`loadingProgress`, `beginAccessingResources`, `endAccessingResources`,
  `conditionallyBeginAccessingResources`) with a `LiveResourceRequest` conformer and a factory
  closure `(Set<String>) -> ResourceRequesting` so production wires the live request and tests
  inject a fake. No network/crypto/hash/signature code — ODR integrity is inherited from App
  Store code-signing.
- **Per-language ODR tag mapping** keyed off catalog `availability == .downloadablePack` for
  fr/de/ko/nah; base languages yield no tags and are never requested.
- **`LanguagePackDownloadState` machine** (`@Observable`, keyed by `AppLocale`):
  `notRequested → downloading(progress:) → available`, plus `failed(retryable:)` with a `retry`
  transition back to `downloading`. Mapped onto the existing `LanguagePackState` so the provider
  seam's `state(for:)` contract is unchanged.
- **`LanguagePackProviderHolder` concurrency hardening**: pinned the previously unisolated mutable
  `active` global to `@MainActor` (story-003 independent-review flag), with call sites
  (`L10n.string`, `GeoNameResolver.resolveThroughProvider`) updated so reads stay race-free when
  the async ODR provider swaps the active provider on download completion. Default
  `BundledLanguagePackProvider` behavior is identical.
- **`ODRLanguagePackProvider`** conforming to `LanguagePackProvider`: lazily issues an ODR request
  via the factory on first selection of a downloadable language; reports
  `notDownloaded`/`downloading`/`available`/`failed` through `state(for:)`; on success resolves the
  downloaded `.lproj` for `stringBundle(for:)` and decodes the downloaded geo JSON through the
  schema-validating `GeoNamePackLoader` for `geoNameData(for:)` (validation failure degrades, no
  crash). Retains the request for the pack's lifetime and ends access on teardown. Base languages
  always report `available` and delegate to the bundled provider (composition, not duplication).
- **Lazy download triggering + graceful degradation**: a `requestDownload(for:)` entry point on the
  selection path kicks off the ODR download without adding delivery-specific branching at resolver
  call sites; on success active resolution switches to that language, on failure/absent pack it
  degrades to the fallback chain (selected → es-MX for ko/nah → en) so the app stays usable and
  fully functional offline with zero packs. `retry` re-issues the request.
- **Tests** with a `FakeResourceRequest` (no live network): state-machine transitions
  (request → progress → success; request → failure → retry), success exposing the downloaded
  bundle/geo data and flipping `state(for:)` to `available`, absent/failed pack falling through to
  bundled base, downloaded-JSON validation failure degrading safely, base languages never
  requested, and offline-with-zero-packs resolution unchanged. Reuses the
  `ProviderRoutedResolutionTests` save/restore-`active` pattern.
- New source/test files registered in `project.yml`; build + tests pass.

## Acceptance criteria

- [x] Non-base languages' content (UI strings + geo translations) delivered via ODR, not compiled
      into the main binary, keyed by ODR tag(s) per language.
- [x] Observable per-language download state machine (notRequested → downloading(progress) →
      available, plus failed + retry) exposed for the picker.
- [x] Selecting a not-yet-downloaded language triggers a lazy ODR download; on success the provider
      returns that pack's bundle + geo data and active resolution switches; request retained for
      pack lifetime and ended appropriately.
- [x] Download failure surfaces a failure state with a retry path that re-issues the request;
      failed/absent pack degrades to the fallback chain.
- [x] ODR provider conforms to the same `LanguagePackProvider` seam with no resolver/picker call-site
      changes beyond observing the state machine.
- [x] Packs are data-only; no custom network/crypto/signature/hash code; pack data schema-validated
      before use with safe degradation on failure.
- [x] App remains fully functional offline with zero packs downloaded.
- [x] New tests cover state-machine transitions and absent-pack fallback using a test fake for
      `NSBundleResourceRequest` (no live network).

## Test plan

- [x] `just` build succeeds
- [x] `just` test suite passes (state machine transitions, ODR provider end-to-end, fallback,
      validation-failure degradation, base-never-requested, offline-with-zero-packs)
- [x] No resolver/picker call site changed beyond observing the state machine and the holder
      isolation update
