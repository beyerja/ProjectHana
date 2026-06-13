# Story 002: Wrong-Click Dual Penalty

## Goal
When the user taps the wrong country, record a failure penalty for both (a) the country currently being quizzed and (b) the country that was incorrectly tapped.

## Acceptance Criteria
- [ ] On an incorrect tap in `MapQuizSession`, SM2 `quality = 1` is applied to the quizzed card AND (if a card for the incorrectly tapped country exists in the current deck) to that card too.
- [ ] In `MapLearningSession`, on an incorrect tap the wrong-tapped country's streak (`consecutiveCorrect`) is reset to 0 if its card exists in the active set.
- [ ] If no card exists in the deck for the incorrectly tapped country, no crash occurs.
- [ ] Unit tests cover: dual penalty applied when both cards present, graceful no-op when tapped country has no card.
- [ ] Existing tests continue to pass.
