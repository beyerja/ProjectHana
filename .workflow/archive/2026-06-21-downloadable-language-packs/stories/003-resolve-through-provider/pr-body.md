## Goal

Wire the resolution call sites (`L10n` string resolution and `Country`/`River`/`MountainRange`/`Sea` localized names) to consult the active `LanguagePackProvider` seam instead of reaching into `Bundle.main` `.lproj` paths and hardcoded struct fields directly. After this story, switching the active language flows through one resolver that asks the provider for the resolved bundle / pack data, with the existing fallback chain (selected → es-MX for ko/nah → en) preserved.

With only the bundled provider (story 002) wired in, behavior is identical to today. This makes the seam the single resolution path, so story 004's ODR provider changes nothing at the call sites.

## Summary of changes

- Add `LanguagePackProviderHolder.active`, a single app-wide swappable holder defaulting to `BundledLanguagePackProvider()`; nothing branches on the concrete provider type.
- Add `GeoNameResolver.resolveThroughProvider(id:locale:field:base:provider:)` that walks `locale.fallbackChain` across the active provider's pack data, keyed by the stable geo id, and falls back to the bundled base value when a pack is absent, omits the id, or fails validation (nil ⇒ fall-through).
- Route `Country.localizedName/localizedCapital` and `River`/`MountainRange`/`Sea` `localizedName` through the resolver; drop the per-instance `namesByCode`/`capitalsByCode` switch as the primary path.
- Route `L10n.string(_:locale:)` through the provider's `stringBundle(for:)` per candidate code, keeping the per-key fallback chain and raw-key terminator; `bundle(for:)` remains as the bundled provider's backing.
- Audit (task 009): no production resolution call site reads `nameFr`/`capitalKo`/… or opens an `.lproj` directly; remaining field reads are model inits, the bundled provider's data-source helpers, and tests asserting pack == field.

## Test plan

- [ ] `L10nBundleResolutionTests` passes against the provider-routed path
- [ ] `LocalizedGeoNameTests` passes (updated to activate a bundled provider built from its own fixtures)
- [ ] `LocalizedQuizPromptTests` passes
- [ ] `NameFeatureQuizTests` and other quiz/name tests using localized names pass
- [ ] New `ProviderRoutedResolutionTests` cover: stub-provider resolution, absent-pack fallback (geo + L10n), malformed-pack degradation, and that the resolver accepts any provider without type branching
- [ ] CI green on `feat/**` trigger
