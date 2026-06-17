# Story 003 — Korean & Nahuatl geographic content

## Title
Add `name_ko`/`name_nah` (and Country `capital_ko`/`capital_nah`) to the JSON resources and surface
them through the models.

## Goal
Localize geographic content — country names + capitals, river names, sea names, mountain-range names
— into Korean and Nahuatl (best-effort), decoded into the model fields added in story 001 so
`localizedName`/`localizedCapital` return them. Missing entries fall back es-MX → en.

## Scope / changes
- `Hanahuac/Resources/countries.json`: add `name_ko`, `name_nah`, `capital_ko`, `capital_nah` to each
  entry where a confident translation exists. Korean: translate country/capital names (Korean
  exonyms are well established — high coverage expected). Nahuatl: provide where a reasonable form
  exists; otherwise omit (falls back to es-MX/en).
- `Hanahuac/Resources/rivers.json`, `seas.json`, `mountains.json`: add `name_ko`/`name_nah`
  analogously.
- Confirm the model decoders from story 001 read these keys (CodingKeys map snake_case →
  `nameKo`/`nameNah`/`capitalKo`/`capitalNah`). If story 001 stubbed the fields without wiring
  decoding, complete the wiring here.
- Do NOT alter existing `name`/`name_fr`/`name_de`/`name_es` values.

## Acceptance criteria
- All four JSON files remain valid JSON and decode without error into their models.
- With Korean selected, country/capital/river/sea/mountain names show Korean where provided, else
  es-MX, else English.
- With Nahuatl selected, names show Nahuatl where provided, else es-MX, else English.
- No regression to existing languages' geographic names.
- A unit test decodes each resource and asserts a sample ko/nah field resolves correctly through the
  fallback chain.
