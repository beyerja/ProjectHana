# Feature: Map Quiz Improvements

## Goal

Improve the map quiz experience across four areas: gesture accuracy, penalty fairness, visual feedback richness, and zoom difficulty calibration. These changes apply to both `MapQuizView` (review/due mode) and `MapLearningQuizView` (learning mode), and their backing sessions.

## Acceptance Criteria

- [ ] Pinch-to-zoom gesture on a country pin is no longer misinterpreted as a tap/click on that pin. Two-finger zoom works cleanly without triggering `handleTap`.
- [ ] When the user taps the wrong country, both the quizzed country (currently being asked) and the incorrectly tapped country have a failure penalty recorded in the SM2 scheduler (quality score penalized for both). In the learning mode, the wrong-tapped country's streak is also reset.
- [ ] When a pin answer is revealed (correct or incorrect), the filled polygon area of the relevant country/countries lights up with a semi-transparent color overlay: green for correct, red for incorrect/wrong-tapped. This uses the existing `CountryBorderLoader` polygon data.
- [ ] The map region shown during the quiz displays a minimum of 10 neighbouring countries visible at once (annotation pins + border polygons). The correct country can appear anywhere in the visible area (center or edges), not always at the center. The minimum visible span is enforced such that the user must know the country's true location and cannot rely on process of elimination from a short list.

## Constraints

- Changes must apply consistently to both `MapQuizView` / `MapQuizSession` and `MapLearningQuizView` / `MapLearningSession`.
- The country highlight overlay must use the existing `CountryBorderLoader.shared` polygon data; no new data files.
- Pinch gesture fix must not break the existing tap-to-answer interaction on device.
- SM2 penalty for wrong-tapped country: apply `quality = 1` to any card in the current deck matching the incorrectly tapped country's ID. If no matching card exists in the deck, record the penalty silently (no crash).
- The 10-country minimum refers to annotation pins shown on the map; the region span must be large enough to show at least 10 countries naturally.
- Zoom/span logic must be shared between `MapQuizSession` and `MapLearningSession` (no duplication).

## Out of Scope

- Changing the quiz flow, card ordering, or SM2 scheduling algorithm beyond the wrong-click dual-penalty.
- Adding new map styles or visual themes.
- Multi-player or networked features.
- Changing the learning graduation mechanic (3-consecutive-correct streak).
- Localization changes beyond what the existing L10n system already supports.
