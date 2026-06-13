## Tasks

- [x] 001: In `MapQuizSession.advance()`, when `answerState == .incorrect(tappedID, correctID)`, find any card in `cards` whose `factID == tappedID` and apply `SM2Scheduler.schedule/apply(quality: 1)` to it before advancing (in addition to the existing penalty already applied to the quizzed card)
- [x] 002: In `MapLearningSession.recordWrong()`, find any card in `activeSet` whose `factID` matches the tapped country ID (from `answerState`) and reset its `consecutiveCorrect = 0` (in addition to the current card already being reset)
- [x] 003: Add unit tests in `MapLearningTests.swift`: (a) dual SM2 penalty in `MapQuizSession` when both cards present, (b) graceful no-op when tapped country has no card, (c) dual streak-reset in `MapLearningSession`
- [x] 004: Run `just test` and fix any failures
