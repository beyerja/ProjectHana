fix(l10n): complete es-ES a11y keys + enforce es-ES in completeness gate

The appstore-readiness a11y stories (004/005) added an `a11y.*` namespace plus
`stats.by_mode` to the canonical key set. es-ES (Castilian, added separately by
#154) was translated against the older key set, so after integrating main it was
missing exactly those 24 new keys. The static l10n gate did not catch this because
its locale list was hardcoded and did not include es-ES; the runtime es-ES
completeness test also no-ops in CI (the ODR pack is not mounted), so the gap
shipped silently behind the es-ES -> es-MX -> en fallback.

- Add the 24 missing keys (23 a11y.* + stats.by_mode) to es-ES with Castilian
  Spanish translations (e.g. "pulsa dos veces" for VoiceOver double-tap).
- Add es-ES to FULL_LOCALES in scripts/check-l10n-completeness.py so the gate now
  holds it to the full canonical key set like de/fr/ko (matching es-ES's own
  feature contract that it ships a complete UI string set), and update the
  justfile / docstring comments accordingly.
- Allowlist the 5 legitimately-identical-to-English es-ES strings (Asia, the
  "%d / 3" format string, General, iCloud, Error) so the untranslated-value
  warning list stays signal.

just lint + just test pass; the gate reports es-ES 156/156.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
