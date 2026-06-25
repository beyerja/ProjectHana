<!-- code-owner-review -->
## Code-owner review — APPROVED (independent second eye)

Independent re-verification of PR #159 (story 004 — Basque `eu`), formed by reading the diff directly
(not the `/code-review` skill) and tracing each new seam to its production call site. Distinct second
judgment, not a rubber-stamp of the first reviewer — reached the same APPROVED conclusion on my own.

### Story-004 contract — all confirmed
- **Fallback `[eu, es-ES, en]`; authored Euskara is real.** Catalog descriptor `Euskara` /
  `[.eu, .esES, .en]` / `.downloadablePack`; `bundleCandidates(for: .eu)` == `["eu","es-ES","en"]`.
  `eu.lproj` is genuine professional Basque (ergative/genitive `%@(r)en`, inessive, `«»`) — not MT,
  not Spanish verbatim. Geo `name_eu`/`capital_eu` carry distinct Basque exonyms plus legitimate
  Basque-equals-Spanish forms.
- **Gap → es-ES before en.** `settings.sync.toggle` deliberately omitted from eu;
  `testBasqueGapKey_resolvesToSpainSpanishBeforeEnglish` asserts the es-ES value AND `!= en`.
- **ODR, tagged `[lang-eu]`, NOT bundled.** `project.yml` lists `eu.lproj` + `eu-geo.json` in BOTH
  `excludes` and resources with `resourceTags: [lang-eu]`; `verify-odr-packs.sh` includes `eu`.
- **es-MX stays device default; eu auto-detects without perturbing es-\*.**
  `testMatchingBasqueDoesNotPerturbSpanish`: `es_ES`/`es-ES` → `.esMX`, `eu`/`eu-ES` → `.eu`.
- **Per-language progress isolation `.eu`** (`testProgressIsolationForBasque`).
- **Catalog/enum invariants** hold (count 9, eu after ca, generic ODR-tag invariants).

### Production wiring
`.eu` arms in `GeoModel+PackData.swift` reference `nameEu`/`capitalEu` correctly (no copy-paste);
catalog descriptor is the live fallback source — nothing left unwired.

### CI
Required checks present and green on head `6ee48b0`: Build & Test ✓, gitleaks ✓ (Lint ✓). No
event-miss; no self-heal needed.

**Verdict: APPROVED.** Formal `Hanahuac-Bot` APPROVED state submitted via the bot wrapper and
confirmed by read-back. No review threads to resolve (round 1, no inline comments).
