# Story 001 Log — Fix Country Polygon Overlay

## Implementation

**Root cause**: SwiftUI's `@MapContentBuilder` closure does not register observation dependencies on `@Observable` objects. Reading `session.answerState` inside the `Map { }` closure never triggered a view update, so polygons always rendered with `.clear`.

**Fix**: Captured `let answerState = session.answerState` at the top of `quizBody(session:)`, which is a `@ViewBuilder` function where `@Observable` tracking does work. Passed `answerState` into the `Map` content closure as a captured local value. Updated `pinState(for:answerState:)` to take `AnswerState` directly instead of reading from the session.

**Files changed**:
- `ProjectHana/Views/Quiz/MapQuiz/MapQuizView.swift`
- `ProjectHana/Views/Quiz/MapQuiz/MapLearningQuizView.swift`

## Status: DONE
