# Story 006: Map Quiz — Tap the Country

## Title
Implement the interactive map quiz where the user taps the correct country on a MapKit map

## Goal
Deliver the primary differentiating quiz mode: a MapKit map with country annotations that the
user taps to answer, with correct/incorrect visual feedback and SM-2 scheduling applied.

## Acceptance Criteria
- [ ] `MapQuizView` presents a `Map` (SwiftUI MapKit) centred on the correct country's centroid
      with a zoom level that shows surrounding context
- [ ] The question prompt is displayed at the top: "Tap [Country Name] on the map"
- [ ] Each of 4–6 nearby (same-continent) countries is shown as a tappable `MapAnnotation` pin
      plus the correct answer (total ≤ 8 annotations to avoid crowding)
- [ ] Tapping the correct annotation: turns it green, shows a brief "Correct!" banner, then
      advances to the next card after 1.5 seconds
- [ ] Tapping an incorrect annotation: turns it red, reveals the correct one in green, shows
      "Incorrect — that was [WrongCountry]" banner, then advances after 2 seconds
- [ ] After each answer the SM-2 scheduler is called: correct = quality 4, incorrect = quality 1
- [ ] Session ends when all due cards in the selected category/filter have been answered; an
      end-of-session summary shows cards reviewed, correct count, and next-due date
- [ ] Quiz session can be exited early via a back/cancel button without crashing
- [ ] No crash during a 20-question session (XCTest UI test or manual verification documented)
