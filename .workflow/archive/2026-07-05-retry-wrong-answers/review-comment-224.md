<!-- independent-review -->
## Independent Review — Round 1

**Verdict: APPROVED**

### What was reviewed

PR #224 changes exactly four lines across four view files, switching `reviewed:` from `session.totalCards` / `session.totalQuestions` (fixed distinct-card count) to `session.reviewedCount` (= `attemptCount`, incremented on every `advance()` including retries).

### Verification

All three session classes (`MapQuizSession`, `MultipleChoiceSession`, `TextQuizSession`) correctly implement `reviewedCount` as a computed property over a private `attemptCount` that is incremented unconditionally in `advance()` — including on the retry path (wrong-answer requeue). At session finish `reviewedCount >= totalCards/totalQuestions` whenever any card was retried, which is exactly the denominator the spec requires for attempt-based accuracy in `QuizSummaryView`.

`QuizSummaryView.accuracy` computes `correct / reviewed * 100`. With the old wiring (`totalCards`), a 5-card session where 2 cards are answered wrong once each would show `5/5 = 100%` accuracy. With the fix (`reviewedCount = 7`), it correctly shows `5/7 ≈ 71%`.

No other callsites, no production-wiring gaps, no regressions. The diff is minimal and correct.

### Findings

No blocking findings. No nits.
