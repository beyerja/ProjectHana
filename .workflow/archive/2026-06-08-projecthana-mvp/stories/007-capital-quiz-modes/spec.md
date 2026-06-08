# Story 007: Capital & Multiple-Choice Quiz Modes

## Title
Implement text-based capital quiz and multiple-choice quiz modes for all fact categories

## Goal
Add the remaining quiz modes that do not require map interaction: capital-name quizzes and
multiple-choice for countries, rivers, mountains, and seas — all driven by the same SM-2 engine.

## Acceptance Criteria
- [ ] `CapitalQuizView` presents: "What is the capital of [Country]?" with a text field; submitting
      (or tapping "Check") evaluates correctness (case-insensitive, trim whitespace); shows
      correct/incorrect feedback with the right answer; advances to next card
- [ ] `ReverseCapitalQuizView` presents: "Which country has [Capital] as its capital?" with the
      same text-field answer mechanic
- [ ] `MultipleChoiceQuizView` works for any category (country, river, mountain, sea): shows a
      question (e.g., "Which river is this?" with a map annotation or name cue) and 4 labelled
      buttons; correct answer is randomly placed; wrong options are plausible same-continent items
- [ ] After each answer the SM-2 scheduler updates the card (correct = quality 4, incorrect = quality 1)
- [ ] `HomeView` category buttons navigate to the appropriate quiz mode (or show a mode picker
      if multiple modes apply); for MVP, Countries → mode picker (map tap vs. capital text vs. MCQ),
      Rivers/Mountains/Seas → MCQ mode with a map annotation cue
- [ ] Session end-of-session summary screen is shared/reused from story 006
- [ ] Unit tests cover: case-insensitive matching, whitespace trimming, wrong-option generation
      (never duplicates, never equals the correct answer)
