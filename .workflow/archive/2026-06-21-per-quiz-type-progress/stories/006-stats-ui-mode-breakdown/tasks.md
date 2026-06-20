# Log — Story 006: Stats per-mode breakdown toggle

## Tasks
- [x] 001: Add `ModeProgressSummary` (mirrors `LanguageProgressSummary`) — per (activeLanguage, mode) reviewed/reviewTier/mastered/due counts from the language's cards filtered by `quizMode`. `all(for language:context:now:)` returns one per `QuizModeID` in display order (modes with no cards yield zeroed rows; typeCapital naturally only has Countries data).
- [x] 002: Add a `modeBreakdownSection` to `StatsView` mirroring `languageBreakdownSection`: a toggle (default collapsed → aggregated view unchanged) revealing per-mode rows (mode name + mastered/review/due metrics). Add a `showModeBreakdown` @State.
- [x] 003: Localize new UI strings (`stats.by_mode` + per-mode display names) across all shipped locales, following the L10n convention. Add `HomeQuizMode`/`QuizModeID` display-name keys if not already present.
- [x] 004: Tests: `ModeProgressSummary.all` returns one summary per mode; a fact graded in one mode shows under that mode only; typeCapital summary has only Countries data; aggregated default numbers unchanged. `just generate`/`lint`/`test` green; visual check via sim screenshot.
