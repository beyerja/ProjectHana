# 003 — Route `L10n` and geo-name resolution through the active provider

## Title
Resolve UI strings and geo names through the `LanguagePackProvider` seam, preserving the
existing fallback chain

## Goal
Wire the call sites (`L10n` string resolution and `Country`/`River`/`MountainRange`/`Sea`
localized names) to consult the active `LanguagePackProvider` instead of reaching into
`Bundle.main` `.lproj` paths and hardcoded struct fields directly. After this story, switching
the active language goes through one resolver that asks the provider for the resolved bundle /
pack data, and the existing fallback chain (selected → es-MX for ko/nah → en) is preserved.

With only the bundled provider (story 002) wired in, behavior is identical to today. This story
makes the seam the single resolution path so story 004's ODR provider changes nothing at call
sites.

## Background (current state)
- `L10n.string(_:locale:)` loops over `bundleCandidates(for:)` opening `Bundle.main` `.lproj`.
- Geo `localizedName(for:)` switches over hardcoded fields.

## Acceptance Criteria
- [ ] `L10n` string resolution consults the active provider's resolved pack bundle(s) in
      addition to / instead of bundled `.lproj`, preserving the existing fallback chain
      (selected → es-MX for ko/nah → en) per key, and still returning the key as the final
      stable fallback.
- [ ] `Country` (and the other geo models') localized name/capital come from the active
      language's pack data via the provider, keyed by language code, falling back through
      es-MX → en. No call site reads `nameFr`/`capitalKo`/… anymore.
- [ ] If the active language's pack is absent/not-yet-downloaded, resolution transparently
      falls back through the chain to a bundled base language; the app never shows broken keys
      or crashes when a pack is missing.
- [ ] A schema/validation/parse failure of pack data degrades safely to the bundled fallback.
- [ ] All call sites go through the provider seam; none branch on the concrete provider type.
- [ ] Existing tests (`L10nBundleResolutionTests`, `LocalizedGeoNameTests`,
      `LocalizedQuizPromptTests`, and the quiz/name tests that use localized names) pass against
      the new resolution path; new tests cover resolution-via-provider and fallback when a pack
      is absent.

## Out of Scope
- ODR download mechanism and state machine (story 004).
- The picker download UI (story 005).
- Adding new languages.
