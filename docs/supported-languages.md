# Supported languages

Hanahuac ships **21 in-app languages**. The single source of truth for the set, the native display
names, the per-language fallback chains, the bundled-vs-downloadable split, and the RTL flag is
`Hanahuac/L10n/LanguageCatalog.swift` (read by `AppLocale` in `Hanahuac/L10n/AppLocale.swift`). This
document describes that set and the contracts around it; if it ever disagrees with the catalog, the
catalog wins.

> **Scope — in-repo docs only.** App Store Connect upload, code signing, and binary/metadata upload are
> **out of scope**: there is no paid Apple Developer account (see [`docs/icloud-sync.md`](icloud-sync.md)
> for the same constraint on live sync). This document and the rest of `docs/` are the deliverable; no
> release/signing/upload step is implied.

## The 21 languages

Codes are the `AppLocale.rawValue` (which is also the `.lproj` directory name and the `lang-<code>` ODR
tag suffix). Display names are shown in the language's own native script. "Content" is the enforcement
role from `scripts/check-l10n-completeness.py` `ROLE_MAP`.

| Language | Code | Native name | Content | Delivery | Direction |
|----------|------|-------------|---------|----------|-----------|
| English | `en` | English | Base (complete) | Bundled (in binary) | LTR |
| Spanish (Mexico) | `es-MX` | Español (México) | Base (complete) | Bundled (in binary) | LTR |
| French | `fr` | Français | Complete | ODR `lang-fr` | LTR |
| German | `de` | Deutsch | Complete | ODR `lang-de` | LTR |
| Spanish (Spain) | `es-ES` | Español (España) | Complete | ODR `lang-es-ES` | LTR |
| Catalan | `ca` | Català | Partial (best-effort) | ODR `lang-ca` | LTR |
| Basque | `eu` | Euskara | Partial (best-effort) | ODR `lang-eu` | LTR |
| Yucatec Maya | `yua` | Màaya t'àan | Partial (best-effort) | ODR `lang-yua` | LTR |
| Italian | `it` | Italiano | Complete | ODR `lang-it` | LTR |
| Polish | `pl` | Polski | Complete | ODR `lang-pl` | LTR |
| Dutch | `nl` | Nederlands | Complete | ODR `lang-nl` | LTR |
| Serbian (Cyrillic) | `sr` | Српски | Complete | ODR `lang-sr` | LTR |
| Korean | `ko` | 한국어 | Complete | ODR `lang-ko` | LTR |
| Nahuatl | `nah` | Nāhuatl | Partial (best-effort) | ODR `lang-nah` | LTR |
| Japanese | `ja` | 日本語 | Complete | ODR `lang-ja` | LTR |
| Chinese (Simplified) | `zh-Hans` | 简体中文 | Complete | ODR `lang-zh-Hans` | LTR |
| Hindi | `hi` | हिन्दी | Complete | ODR `lang-hi` | LTR |
| Arabic | `ar` | العربية | Complete | ODR `lang-ar` | **RTL** |
| Bengali | `bn` | বাংলা | Complete | ODR `lang-bn` | LTR |
| Portuguese (Brazil) | `pt-BR` | Português (Brasil) | Complete | ODR `lang-pt-BR` | LTR |
| Urdu | `ur` | اردو | Complete | ODR `lang-ur` | **RTL** |

**Right-to-left:** Arabic (`ar`) and Urdu (`ur`) are written right-to-left. Their
`LanguageDescriptor.textDirection` is `.rightToLeft` (every other language is `.leftToRight`), surfaced
by `AppLocale.isRTL`. Selecting either language mirrors the **whole app's** `layoutDirection`,
independently of the device locale — see `docs/` and the RTL UI-walkthrough recipe
(`just ui-walkthrough-rtl`).

## Content contracts: complete vs best-effort

Each language carries one of two content contracts, classified per locale in the
`scripts/check-l10n-completeness.py` `ROLE_MAP`:

- **Complete / no-fallback** — `BASE` (`en`, `es-MX`) plus `FULL` (`fr`, `de`, `es-ES`, `it`, `pl`,
  `nl`, `sr`, `ko`, `ja`, `zh-Hans`, `hi`, `ar`, `bn`, `pt-BR`, `ur`). These carry the **full** canonical
  UI-key set and full bundled-geo name coverage, so **no link in their fallback chain is ever exercised
  in practice** — every key resolves from the locale itself. Most chains are simply `[<self>, en]` with
  English as an ultimate, never-hit safety net (e.g. `it` → `[it, en]`); a few include an intermediate
  locale (`es-ES` → `[es-ES, es-MX, en]`, `ko` → `[ko, es-MX, en]`), but because coverage is complete
  that intermediate is never reached either. A missing UI key or geo name for one of these locales is a
  **defect** and fails CI (see gates below).

- **Partial / best-effort by design** — `PARTIAL`: `ca`, `eu`, `yua`, `nah`. These are intentionally
  allowed to have gaps; genuine gaps resolve through each locale's fallback chain rather than failing:
  - `ca` → `[ca, es-ES, en]`
  - `eu` → `[eu, es-ES, en]`
  - `yua` → `[yua, es-MX, en]`
  - `nah` → `[nah, es-MX, en]`

  Their coverage is reported **informationally** by the completeness gate, never as a failure.

The `SCAFFOLDED` role (content-pending placeholder) exists in the gate for future use but is currently
**unused** — every language landed by the plumbing story has since been flipped to its final role.

## The "no fallbacks" contract and how it is enforced

For the complete languages above, every UI string and every bundled-geo name must be present so the
fallback chain's English tail is never reached in practice. Two complementary gates enforce this; a
missing key or geo name **fails CI**:

1. **Static gate — `just l10n-check`** (`scripts/check-l10n-completeness.py`, folded into `just lint`
   and the CI lint job). Stdlib-only Python. It discovers the on-disk `Hanahuac/<code>.lproj` set,
   requires every on-disk locale to have a declared role in `ROLE_MAP` (an unclassified `.lproj` fails),
   builds the canonical key set as the union of all locales' keys, and asserts that every `BASE`/`FULL`
   locale contains the **full** canonical key set. Any missing key fails, naming the locale and the
   offending keys. It also warns on values byte-identical to English (a likely un-translated copy-paste),
   with a scoped allowlist for legitimately-shared strings (brand names, format strings, identical
   cognates). This is the **UI-string** half of the contract.

2. **Runtime gate — strict XCTest** (`HanahuacTests/L10nCompletenessTests.swift` +
   `HanahuacTests/LanguageCompletenessSupport.swift` / `LanguageCompletenessSupportTests.swift`, run by
   `just test`). The support layer offers a **strict** path
   (`missingUIKeysStrict(for:)` / `geoCoverageGapsStrict(for:)`) that distinguishes "pack unreachable"
   from "no gaps": when a pack expected to be present cannot be resolved it **throws**
   (`CompletenessError`) rather than silently returning "no gaps", so a real gap — or a missing pack —
   fails CI. This is what gives the geo-coverage half of the "no fallbacks" bar teeth: it resolves the
   active `LanguagePackProvider`'s validated geo-name data against the bundled source geo
   (countries/rivers/mountains/seas + capitals) and reports any entity lacking a localized name.

Between them: the static gate covers **UI keys**, the runtime strict test covers **geo-name coverage**.

## Device-locale auto-selection

On first run (no explicit user choice) the app maps the device `Locale` to an `AppLocale` via
`AppLocale.matching(_:)`. The resolution order is:

1. Any `es-*` locale → `es-MX` (Spanish never auto-selects `es-ES`).
2. The Nahuatl macrolanguage code `nah` and its common ISO 639-3 individual codes (`nhn`, `nch`, `ncj`,
   `ngu`, `nhe`) → `nah`.
3. **Generic `zh*`** (`zh`, `zh-Hans`, `zh-Hant`, `zh-CN`, …) → `zh-Hans`, and **generic `pt*`** (`pt`,
   `pt-BR`, `pt-PT`, …) → `pt-BR`. These two macrolanguage → regional collapses mirror the `es` → `es-MX`
   pattern, which the plain code lookup cannot express.
4. Match by language code against the catalog (`code == rawValue`): `en`, `fr`, `de`, `ca`, `eu`, `yua`,
   `it`, `pl`, `nl`, `sr`, `ko`, plus the regional-code-free `ja`, `hi`, `ar`, `bn`, `ur`.
5. Anything unrecognized → `en`.

The user can always override the auto-selection in the in-app language picker.

## On-Demand Resource delivery (`lang-<code>`)

- **Bundled base (in the app binary, no ODR tag):** `en` and `es-MX`. These are always present, so the
  app is fully usable offline with **zero** packs downloaded — every other language's fallback chain
  terminates at `es-MX`/`en`.
- **Downloadable packs (On-Demand Resources):** the other **19** languages. Each is delivered by exactly
  one ODR tag `lang-<code>` (e.g. `lang-fr`, `lang-zh-Hans`, `lang-pt-BR`) carrying both that language's
  `.lproj` UI strings **and** its `<code>-geo.json` geo-name pack. The tag string is the contract between
  the build (`project.yml` `resourceTags`) and the runtime (`LanguageDescriptor.odrTags`, requested by
  `ODRLanguagePackProvider`); the two must match exactly.

Packs are built **per app version** from the in-tree source data and refresh with the app on update;
there is **no** out-of-band/OTA pack-update channel. Full build/packaging details, the tag contract, geo
pack generation, and the async validation CI are in [`docs/odr-packaging.md`](odr-packaging.md).
