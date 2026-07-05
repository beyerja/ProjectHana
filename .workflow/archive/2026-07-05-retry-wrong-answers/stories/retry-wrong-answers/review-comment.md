<!-- independent-review -->
## Independent Review — Round 1: APPROVED

**Verdict:** No blocking findings. The change is correct, consistent with the two sibling sessions already merged (MapQuizSession / MultipleChoiceSession), and all CI checks pass.

### What was checked

**Core logic (`TextQuizSession.advance()`)**
- Reinsertion range formula `Int.random(in: max(1, currentIndex) ..< max(2, questions.count + 1))` is identical to MultipleChoiceSession and MapQuizSession.
- The `min(insertAt, questions.count)` clamp correctly handles the 1-question edge case: after removing the only question, `questions.count == 0`, so `min(1, 0) == 0`, reinserting the question at index 0 so `current` immediately returns it again.
- `correctCount == totalQuestions` checked before the safety `currentIndex >= questions.count` guard — primary termination condition first, safety fallback second. Different order from MapQuizSession but produces the same observable outcome; the ordering here is clearer.
- `currentIndex` is never incremented on a wrong answer, so it stays in `[0, totalQuestions-1]` while `isFinished == false`. The progress display `currentIndex + 1 / totalQuestions` cannot exceed `totalQuestions / totalQuestions` while the view is visible.

**View changes**
- Both `CapitalQuizView` and `NameFeatureQuizView` correctly migrate from `session.reviewedCount + 1 / session.questions.count` to `session.currentIndex + 1 / session.totalQuestions` for the in-progress counter.
- `QuizSummaryView(reviewed: session.totalQuestions, ...)` is consistent with `MultipleChoiceQuizView` (same pattern) and `MapQuizView` (uses `session.totalCards`, its equivalent).

**Tests**
- 5 tests in `TextQuizSessionRetryTests` cover: wrong-answer reinsertion, session not finished after one wrong answer, session finishes only when all correct, `reviewedCount` counts all attempts, and `correctCount == totalQuestions` on finish.
- The `answerWrong` helper correctly sets `answerState = .incorrect(...)` before calling `advance()`, so the reinsertion branch fires as intended.

**No production wiring gap**
- `TextQuizSession` is already the live session class constructed directly in `CapitalQuizView.buildIfNeeded()` and `NameFeatureQuizView.buildIfNeeded()`. No new protocol or provider to wire; the change is in-place on existing construction sites.

**CI:** All checks pass (Build & Test, Lint, gitleaks).
