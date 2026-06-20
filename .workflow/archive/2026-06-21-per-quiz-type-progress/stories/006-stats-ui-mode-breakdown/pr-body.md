## Goal

Complete the per-quiz-type progress feature: the Progress screen keeps showing **mode-aggregated**
totals by default and adds a collapsible **per-quiz-type breakdown**. (Story 6 of 6.)

## Changes

- **`ModeProgressSummary`** (mirrors `LanguageProgressSummary`) computes reviewed / review-tier /
  mastered / due per `QuizModeID` within the active language. `typeCapital` naturally surfaces only its
  Countries cards; empty modes yield zeroed rows; the summary ignores other languages.
- **`StatsView.modeBreakdownSection`** mirrors the existing per-language breakdown: a toggle, collapsed
  by default so the default aggregated totals are byte-identical, that expands to show each mode's
  totals. Mode row labels reuse the existing `quiz.mode.*.title` strings.
- **Localized `stats.by_mode`** across en/fr/de/es-MX/ko; `nah` resolves through its es-MX→en fallback
  chain (consistent with how it already resolves `stats.by_language`).

## Test plan

- [x] `just lint` clean
- [x] `just test` — TEST SUCCEEDED
- [x] New `ModeProgressSummaryTests`: one summary per mode in display order, a fact graded in one mode
      shows under that mode only, empty modes zero out, summary ignores other languages.
- [x] App builds + launches cleanly on the simulator (Progress section renders; the toggle mirrors the
      proven per-language breakdown). Aggregated default totals unchanged (toggle collapsed).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
