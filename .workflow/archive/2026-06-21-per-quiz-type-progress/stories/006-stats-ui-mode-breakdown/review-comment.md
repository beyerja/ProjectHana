<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context 4-eye review of the Progress-screen per-mode breakdown.

**Verdict: APPROVED** — no blocking findings.

### Correctness
- **Default unchanged:** `modeBreakdownSection` is collapsed by default (`showModeBreakdown = false`),
  so the Progress screen's default aggregated totals (from `cardStoreProvider.allCards`/`dueCards`) are
  byte-identical. The toggle only adds an opt-in breakdown. ✓
- **`ModeProgressSummary` mirrors the proven `LanguageProgressSummary`** — read-only, same
  `MasteryTier.classify` logic, but scoped to `(language, quizMode)`. It ignores other languages
  (test-covered) and `typeCapital` naturally surfaces only its Countries cards. ✓
- **Row labels** reuse the existing `quiz.mode.*.title` keys via `HomeQuizMode(quizModeID:).titleKey`
  (all four keys exist in `en`); display order follows `QuizModeID.allCases`. ✓
- **L10n:** `stats.by_mode` added to en/fr/de/es-MX/ko; `nah` resolves through its es-MX→en fallback
  chain — consistent with how it already resolves `stats.by_language` (also absent in `nah`). ✓
- Tests cover one-summary-per-mode ordering, single-mode attribution, zeroed empty modes, and
  cross-language isolation.

Note: like the existing per-language breakdown it re-fetches per render when expanded (N fetches) —
same established pattern, not a hot path; not a finding.

Ready to merge. This completes the per-quiz-type-progress feature.
