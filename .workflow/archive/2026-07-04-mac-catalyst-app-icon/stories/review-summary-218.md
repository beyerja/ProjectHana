<!-- independent-review -->

## Independent Review — Round 1 — CHANGES_REQUESTED

**Verdict: CHANGES_REQUESTED**

One blocking bug found. All other candidates were verified clean.

### Blocking finding

**`QuizSummaryView` receives `session.reviewedCount` (attempt count) instead of `session.totalQuestions` in both TextQuiz views.**

- `CapitalQuizView.swift` line 58: `reviewed: session.reviewedCount`
- `NameFeatureQuizView.swift` line 67: `reviewed: session.reviewedCount`

With the retry mechanic, `reviewedCount = attemptCount` (total `advance()` calls including retries). This inflates the "Cards Reviewed" count and deflates accuracy on the summary screen. For a 5-question session with 2 retries the summary shows "Reviewed: 7, Accuracy: 71%" even though the user answered every card correctly.

This is precisely the bug PR #215 (MCQ story) already caught and fixed — the MCQ commit message documents it explicitly: _"Bug 2: QuizSummaryView received session.reviewedCount (attemptCount) as the reviewed count, inflating 'Cards Reviewed' and deflating accuracy. Fixed to session.totalQuestions."_ The fix is `reviewed: session.totalQuestions` in both views.

### What was reviewed and found clean

- **Retry queue logic in `advance()`** — correct and faithful copy of the MapQuizSession / MultipleChoiceSession pattern.
- **`currentIndex + 1 / totalQuestions` progress text** — correct. `currentIndex` equals `correctCount` invariantly (both increment only on correct answers), so the label reads "Nth correctly-answered slot" and never overflows or freezes in a misleading way.
- **SM-2 and StreakTracker on every `advance()`** — intentional per spec ("SM-2 penalty applied on each attempt, compounding — double SM-2 per retry cycle is intentional"). Matches Stories 1 and 2 exactly.
- **`questions.count` always equals `totalQuestions`** — invariant holds (wrong answers are remove+insert, net zero change).
- **Termination conditions** — `correctCount == totalQuestions` fires correctly; `currentIndex >= questions.count` safety guard is a valid backstop. Ordering difference from MapQuizSession is stylistic, not functional.
- **`nextDueDate` at finish** — array retains all N items at session end; no nil risk.
- **Tests** — 5 tests cover all key ACs. Adequate.

### Fix required

In `CapitalQuizView.swift` and `NameFeatureQuizView.swift`, change `reviewed: session.reviewedCount` to `reviewed: session.totalQuestions` in the `QuizSummaryView` call.
