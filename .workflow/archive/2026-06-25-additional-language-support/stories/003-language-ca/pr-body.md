## Goal

Add Catalan (`ca`) as a downloadable On-Demand Resources (ODR) language with the native display
name "Català", authored with real, professional Catalan for UI and geo content where feasible and
relying on the fallback chain `[ca, es-ES, en]` for any genuine gaps.

Builds atop the merged Spanish (Spain) `es-ES` language (#154), which is the intermediate fallback
target in the chain.

## Summary of changes

- **`ca` added as a downloadable language** "Català" via an ODR pack, not bundled into the base app.
- **Fallback chain `[ca, es-ES, en]`** — Catalan first, then Spanish (Spain), then English.
- **Real professional Catalan authored** for UI strings and geo content, with permitted gaps that
  resolve through `es-ES` before reaching `en`.
- **ODR packaging:** `ca.lproj` + `ca-geo.json` tagged `[lang-ca]` and excluded from the bundle;
  `ca` is NOT bundled.
- **Device-locale default preserved:** the `es-MX` device-locale default is untouched; `es_ES` still
  maps to `.esMX` as before — adding `ca` does not perturb `es-*` mapping.
- **Per-language progress isolation** for `.ca`.
- **Deliberate fallback test** asserting that a key with a gap in `ca` resolves to the `es-ES` value
  before falling through to `en` (chain order verified through Spanish).

## Test plan

- [ ] Picker shows "Català" for `ca`.
- [ ] Fallback chain `[ca, es-ES, en]` resolves correctly; a `ca` gap resolves to the `es-ES` value
      before `en`.
- [ ] `ca.lproj` + `ca-geo.json` exist, tagged `[lang-ca]`, excluded from bundle; `ca` not bundled.
- [ ] Per-language progress isolated for `.ca`.
- [ ] Catalog/enum invariants hold.
- [ ] `just lint`, `just test`, `just geo-packs-check`, `just verify-odr-packs`, and an iOS/Catalyst
      build pass. CI green.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
