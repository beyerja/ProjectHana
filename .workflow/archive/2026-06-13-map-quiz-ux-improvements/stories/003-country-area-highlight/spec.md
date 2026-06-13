# Story 003: Country Area Highlight on Answer

## Goal
After the user taps a pin and the answer is revealed, fill the polygon area of the relevant country/countries with a semi-transparent color overlay matching the pin color (green for correct, red for incorrect/wrong-tapped).

## Acceptance Criteria
- [ ] On a correct answer, the correct country's polygon area is filled with a semi-transparent green overlay.
- [ ] On an incorrect answer, the tapped (wrong) country's polygon is filled semi-transparent red, and the correct country's polygon is filled semi-transparent green.
- [ ] The overlay uses `CountryBorderLoader.shared` polygon data (no new data files).
- [ ] The overlay disappears when the quiz advances to the next question.
- [ ] The fix applies to both `MapQuizView` and `MapLearningQuizView`.
- [ ] Existing tests continue to pass.
