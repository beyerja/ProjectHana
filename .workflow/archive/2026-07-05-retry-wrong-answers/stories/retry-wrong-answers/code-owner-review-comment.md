<!-- code-owner-review -->
## Code Owner Review — APPROVED

**Verdict:** APPROVED

**Head SHA:** `38fce8ce4f6e33b88e4cfbf6d0a4e216658d9048`

The diff is 4 one-line changes across the four quiz views (MapQuizView, MultipleChoiceQuizView, CapitalQuizView, NameFeatureQuizView), each replacing `session.totalCards`/`session.totalQuestions` with `session.reviewedCount` in the `QuizSummaryView` call site.

- `reviewedCount` is correctly defined in all three session classes: `MapQuizSession`, `MultipleChoiceSession`, `TextQuizSession`.
- CI all green: Build & Test, Lint, gitleaks, Detect build-relevant changes — all `success`.
- The fix is minimal, complete, and correct. No regressions, no unmet acceptance criteria.

Gate check `code-owner-review` posted as **success** (app_id 4144849, verified via read-back).
