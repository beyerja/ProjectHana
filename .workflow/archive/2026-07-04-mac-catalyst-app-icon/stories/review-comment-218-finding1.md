**Bug: `QuizSummaryView` receives `session.reviewedCount` (= retry attempt count) instead of `session.totalQuestions`**

`CapitalQuizView.swift` line 58 and `NameFeatureQuizView.swift` line 67 both pass `reviewed: session.reviewedCount` to `QuizSummaryView`. With the retry mechanic, `reviewedCount` now equals `attemptCount` — the total number of `advance()` calls including retries for wrong answers.

`QuizSummaryView` uses the `reviewed` value for two things:
1. The "Cards Reviewed" stat row label
2. The accuracy calculation: `Int((Double(correct) / Double(reviewed)) * 100)`

For a 5-question session where the user retries 2 questions: `reviewed = 7`, `correct = 5`, accuracy = 71% — even though the user correctly answered every question. The "Cards Reviewed" row shows 7 instead of 5.

This exact bug was already found and fixed in PR #215 (MCQ story). The commit message for that fix reads:

> Bug 2: QuizSummaryView received session.reviewedCount (attemptCount) as the reviewed count, inflating "Cards Reviewed" and deflating accuracy. Fixed to session.totalQuestions.

The fix is the same here:

```swift
// CapitalQuizView.swift line 57-60
QuizSummaryView(
    reviewed: session.totalQuestions,   // was: session.reviewedCount
    correct: session.correctCount,
    nextDue: session.nextDueDate
)
```

```swift
// NameFeatureQuizView.swift line 66-69
QuizSummaryView(
    reviewed: session.totalQuestions,   // was: session.reviewedCount
    correct: session.correctCount,
    nextDue: session.nextDueDate
)
```
