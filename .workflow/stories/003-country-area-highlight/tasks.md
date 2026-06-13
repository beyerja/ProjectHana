## Tasks

- [x] 001: In `MapQuizView.quizBody`, change the `MapPolygon` loop to call a helper `fillColor(for:answerState:)` that returns `.green.opacity(0.35)` for the correct country, `.red.opacity(0.35)` for the incorrectly-tapped country, and `.clear` for all others; pass the result to `.foregroundStyle(...)` on each polygon
- [x] 002: Apply the same `fillColor` helper to `MapLearningQuizView.quizBody`
- [x] 003: Extract `fillColor(for:answerState:)` as a free function or `AnswerState` extension in `MapQuizSession.swift` so both views share the same logic without duplication
- [x] 004: Run `just test` and fix any failures
