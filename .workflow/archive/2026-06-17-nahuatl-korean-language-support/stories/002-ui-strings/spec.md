# Story 002 — Korean & Nahuatl UI string translations

## Title
Populate `ko.lproj` and `nah.lproj` Localizable.strings with best-effort UI translations.

## Goal
Translate the ~122 UI string keys into Korean and into Nahuatl (best-effort), so the app UI renders
in the selected language. Keys intentionally left untranslated will fall back to es-MX → en via the
chain shipped in story 001 — this is acceptable, especially for Nahuatl where full coverage is not
expected.

## Scope / changes
- `Hanahuac/ko.lproj/Localizable.strings`: translate all keys to Korean. Use the existing
  `es-MX.lproj/Localizable.strings` (and `en.lproj`) as the source of keys/format specifiers.
  Preserve every `%@`/`%lld`/positional specifier exactly. Keep the same key set/comments structure.
- `Hanahuac/nah.lproj/Localizable.strings`: translate the keys to generic (Classical-leaning)
  Nahuatl where a confident rendering exists; for terms without a reliable Nahuatl form, omit the
  key so it falls back to es-MX (preferred) then en. Document in a header comment that omissions are
  intentional fallbacks.

## Acceptance criteria
- Both files parse as valid `.strings` (no syntax errors; build's strings validation passes).
- Every key present uses the same format specifiers as the English/es-MX source (no specifier drift).
- Selecting Korean renders the UI in Korean across major screens (home/categories, settings, quiz,
  stats).
- Selecting Nahuatl renders Nahuatl where provided and es-MX (then en) for omitted keys — no raw keys.
- No regression to other languages.
