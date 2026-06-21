# 002 — `LanguagePackProvider` seam + bundled provider + geo-name pack data model

## Title
Introduce the `LanguagePackProvider` abstraction with a bundled implementation, and move
geo-name translations off hardcoded per-language struct fields into pack data keyed by code

## Goal
Create the provider seam the whole feature pivots on, and ship it with a working **bundled**
implementation so the build stays green and offline-usable before any ODR code exists. This
story generalizes the existing concrete geo-name and string lookup over a protocol; the ODR
variant (story 004) and the future signed-CDN variant plug in here WITHOUT touching call sites.

A "pack" for a language is DATA-ONLY: the per-language UI strings and that language's
geo-name/capital translations (countries, rivers, mountains, seas). This story defines the
pack data schema and a schema-validated loader, with the **bundled** packs (built from the
existing `.lproj` + the geo JSON that ships in the app) as the first variant.

## Background (current state)
- `Country`, `River`, `MountainRange`, `Sea` each carry hardcoded `nameFr`/`nameKo`/… (and
  `capital*`) optional fields plus a per-locale `switch` in `localizedName`/`localizedCapital`.
- `L10n` reads `Bundle.main.path(forResource: code, ofType: "lproj")` directly.
- `GeographyDataLoader` decodes bundled `countries.json` etc. into those structs.

## Acceptance Criteria
- [ ] A `LanguagePackProvider` (or equivalently named) protocol defines the seam: given a
      language code, return the resolved string lookup source (e.g. a `Bundle` / string table)
      and the geo-name translation data for that language, plus the availability/state needed
      so call sites never branch on "ODR vs bundled vs CDN".
- [ ] A concrete **bundled** provider conforms to the protocol using the resources that ship in
      the app today (the base-language `.lproj` and geo JSON). With only the bundled provider
      wired in, the app is fully usable with ZERO packs downloaded.
- [ ] A versioned, schema-validated pack-data model exists for geo names (language code → geo
      id → localized name/capital) as JSON. The loader schema-validates before use; a
      parse/validation failure degrades safely to the bundled fallback and never crashes
      (no `fatalError` on pack data — contrast current `GeographyDataLoader.fatalError`).
- [ ] Geo models (`Country`, `River`, `MountainRange`, `Sea`) no longer depend on hardcoded
      per-language fields (`nameFr`, `capitalKo`, …) + `switch` arms for their localized names;
      localized names are sourced from the active language's pack data keyed by language code.
      (Resolution wiring through the active provider is finished in story 003; this story
      establishes the data path and keeps `localizedName(for:)`/`localizedCapital(for:)`
      working via the bundled provider so the build and existing tests stay green.)
- [ ] Pack data is DATA-ONLY (strings + JSON), never executable. NO custom
      network/crypto/signature-verification code is introduced.
- [ ] The protocol is shaped so the FUTURE signed-CDN provider (Ed25519 + SHA-256 + pinned key
      + zip-slip-safe extraction) is implementable later without changing call sites — but that
      provider is NOT implemented here.
- [ ] New tests cover the bundled provider, pack-data schema validation (including a malformed
      pack degrading to fallback), and geo-name resolution via pack data. Existing
      `LocalizedGeoNameTests` pass against the new mechanism.

## Out of Scope
- ODR download / `NSBundleResourceRequest` (story 004).
- The picker download UI (story 005).
- The signed-CDN provider implementation (seam only).
- Adding new languages.
