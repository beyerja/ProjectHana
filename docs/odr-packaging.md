# On-Demand Resource language packs — build & packaging

This document describes how Hanahuac's non-base language packs ship as Apple **On-Demand Resources
(ODR)**, how the build is configured (reproducibly, from `project.yml`), how the geo-name packs are
produced, the release-tied versioning rule, how to add a language, and the async validation CI. It is
the reference for cutting a release whose packs are wired correctly.

## What ships where

The two base languages (`en`, `es-MX`) are **always bundled** in the main app binary and carry **no ODR
tag**, so the app is fully usable offline with zero packs downloaded: every non-base language's
fallback chain ends at `es-MX`/`en` (see `LanguageCatalog`).

| Language | Code | `.lproj` UI strings | Geo-name pack | Delivery |
|----------|------|---------------------|---------------|----------|
| English  | `en` | always bundled | — (resolver fallback) | in the app binary |
| Spanish (Mexico) | `es-MX` | always bundled | — (bundled base) | in the app binary |

The other **19** languages are **downloadable On-Demand Resource packs**, each delivered by exactly one
`lang-<code>` tag carrying its `.lproj` UI strings plus its `<code>-geo.json` geo-name pack:
`fr`, `de`, `es-ES`, `ca`, `eu`, `yua`, `it`, `pl`, `nl`, `sr`, `ko`, `nah`, `ja`, `zh-Hans`, `hi`,
`ar`, `bn`, `pt-BR`, `ur`. For the full per-language native names, content contracts (complete vs
best-effort), and the RTL set (`ar`, `ur`), see [Supported languages](supported-languages.md).

## The `lang-<code>` tag contract

Each downloadable language is delivered by exactly one ODR tag named `lang-<code>` (one per non-base
language — `lang-fr`, `lang-de`, …, `lang-zh-Hans`, `lang-pt-BR`, `lang-ur`). This string is the
contract between the **build** and the **runtime**:

- Runtime: `LanguageDescriptor.odrTags` defaults to `["lang-<code>"]` for a `.downloadablePack`
  language and `[]` for a `.bundledBase` language (`Hanahuac/L10n/LanguageDescriptor.swift`). The
  `ODRLanguagePackProvider` keys its `NSBundleResourceRequest` off exactly these tags.
- Build: `project.yml` assigns the same `lang-<code>` tag to that language's `.lproj` **and** its
  `<code>-geo.json` (for all 19 non-base languages).

The build's tags and the provider's requested tags must match exactly; both `scripts/verify-odr-packs.sh`
and the async CI assert this.

## How tags are declared in `project.yml`

The Xcode project is **generated** by XcodeGen — never hand-edit `Hanahuac.xcodeproj`. In
`project.yml`, the `Hanahuac` target:

1. Pulls in the whole source tree (`sources: - path: Hanahuac`) but **excludes** the 19 non-base
   `.lproj` and the 19 `<code>-geo.json`, so they are not auto-folded into the always-bundled
   resources / a single `Localizable.strings` variant group.
2. Re-adds each non-base `.lproj` as a **folder reference** (`type: folder`) and each
   `<code>-geo.json` as a resource, each with `resourceTags: [lang-<code>]` and
   `buildPhase: resources`.

XcodeGen emits `ASSET_TAGS = ("lang-<code>")` on each tagged build file and a project-level
`knownAssetTags` listing one `lang-<code>` per non-base language. The `.lproj` folder references stay
resolvable at runtime via `Bundle.main.path(forResource: code, ofType: "lproj")` once the pack is
present.

Regenerate after any `project.yml` change:

```sh
just generate      # xcodegen generate
just build-mac     # prove the tagged project compiles
```

## Producing the geo-name packs

The non-base geo names (country/river/mountain/sea names + country capitals) ship as data-only ODR
JSON, generated from the bundled source data (`Hanahuac/Resources/{countries,rivers,mountains,seas}.json`)
into the `GeoNamePackData` schema (`Hanahuac/L10n/Packs/GeoNamePackData.swift`):

```sh
just geo-packs         # regenerate Hanahuac/Resources/<code>-geo.json for every non-base language
just geo-packs-check   # verify the committed packs are up to date (CI gate)
```

Generator: `scripts/generate-geo-packs.py`. It emits one pack per downloadable language (every non-base
language in `PACK_LANGUAGES`) with deterministic, sorted output so regeneration produces a clean diff.
The English base
name is intentionally **not** in any pack — it lives on the geo model and is the resolver's final
fallback. `es-MX` has no separate geo pack: it is a bundled base language. Each pack decodes and
validates through `GeoNamePackLoader`; a malformed/unsupported pack degrades safely to the fallback
chain rather than crashing.

**Whenever the source geo JSON changes, rerun `just geo-packs` and commit the regenerated packs.**

## Release-tied versioning (no OTA)

Pack versioning is tied to the app release. There is **no independent / out-of-band / OTA pack update
path**:

- Packs are built **per app version** from the in-tree source data (the `.lproj` strings and the
  generated `<code>-geo.json`). They are part of the same source tree and archive as the app binary.
- Apple hosts and code-signs the asset packs alongside the app; an installed pack **refreshes on app
  update** along with the app, governed by the app's bundle/marketing version. No build setting
  introduces a separate pack-update channel.
- The `GeoNamePackData.version` field is a **schema** guard (the loader rejects an incompatible future
  schema), not an OTA content-version channel.

This means a pack can never be newer or older than the app that requests it.

## Data-only guarantee & integrity

Packs are **data-only**: only `.strings` and `.json` files, never Mach-O / executable / script
content. Integrity is inherited entirely from **Apple App Store ODR code-signing** — there is
deliberately **no** custom network, crypto, signature, or hash-verification trust code in the
language-pack sources.

`scripts/verify-odr-packs.sh` (wired to `just verify-odr-packs`) enforces all of this:

1. The generated project declares exactly the `lang-<code>` tags and assigns each non-base `.lproj`
   and `<code>-geo.json` to the matching tag.
2. The base languages (`en`, `es-MX`) carry no ODR tag.
3. Every ODR-tagged resource is a `.strings`/`.json` data file (no executable content).
4. Each `<code>-geo.json` is well-formed in the `GeoNamePackData` shape and up to date with the source.
5. No custom network/crypto/signature/hash code exists in `Hanahuac/L10n` (comments documenting the
   future signed-CDN design are ignored).

## Async validation CI (not a per-PR gate)

ODR validation is **slow** (it builds the app on a macOS runner), so it is **not** a blocking per-PR
check — the fast, blocking checks (`ci.yml`, `lint.yml`) stay fast and unchanged. Mirroring
`codeql.yml` / `secret-scan.yml`, `.github/workflows/odr-validation.yml` runs on **push to `main`** and
on a **weekly schedule** (with a `concurrency` group and manual `workflow_dispatch`), NOT on
`pull_request`. The job:

1. Regenerates the project (`xcodegen generate`) so it validates exactly what a release build produces.
2. Asserts the geo packs are up to date (`generate-geo-packs.py --check`).
3. Runs the data-only + tag-contract + no-trust-code check (`verify-odr-packs.sh`).
4. Builds the app (proves the tagged project compiles).
5. Validates the zero-packs base-only path: a static bundle check
   (`verify-base-only-bundle.sh` — base languages present, non-base declared on-demand) plus the
   runtime language-pack tests, which exercise resolving strings/geo names with **no packs
   downloaded**, degrading through the fallback chain without crashing.

> **Platform note.** ODR pack *splitting* (resources hosted by Apple, absent until downloaded) is an
> **iOS-device / App Store** mechanism. On **Mac Catalyst** and the **Simulator**, Xcode always embeds
> tagged resources into the app for local development, so a static "packs absent from the bundle" check
> cannot pass on those build platforms — the base-only bundle check therefore reports embedding as
> informational and relies on the tag-contract + runtime checks for the cross-platform guarantee.

Local equivalents:

```sh
just geo-packs-check
just verify-odr-packs
just verify-base-only     # builds Mac Catalyst, then runs the base-only bundle check
```

## Adding a language's pack

1. Add the `LanguageDescriptor` entry in `LanguageCatalog` with `availability: .downloadablePack`
   (its tag defaults to `lang-<code>`) and a new `AppLocale` case.
2. Add the `<code>.lproj/Localizable.strings` UI strings.
3. Add the per-language columns (`name_<code>`, `capital_<code>`) to the source geo JSON, then add the
   code to `PACK_LANGUAGES`/`SUFFIX_BY_CODE` in `scripts/generate-geo-packs.py` and run `just geo-packs`.
4. In `project.yml`: add `<code>.lproj` (folder ref) and `Resources/<code>-geo.json`, each with
   `resourceTags: [lang-<code>]`, and add both to the `excludes` for the main `Hanahuac` source path.
5. `just generate && just build-mac && just verify-odr-packs`.
