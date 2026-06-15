# Story 005 — Expose the Map mode for rivers, mountains, seas on Home

## Title
Wire the `.mapQuiz` mode into the rivers, mountains, and seas Home sections

## Goal
Now that the generalized map quiz supports all categories, expose the **Map**
mode row in the Home screen for rivers, mountains, and seas (it currently shows
only for countries). This is the final integration slice that makes the feature
user-reachable end-to-end.

## Scope / design notes
- In `HomeView.categorySections`, add `.mapQuiz` to the `modes:` arrays for
  `.river`, `.mountain`, and `.sea` (countries already have it). Order it first
  to match countries.
- Confirm `HomeView.directQuizView` already routes `(.mapQuiz, .new)` →
  `MapLearningQuizView(category:)` and `(.mapQuiz, .pending)` →
  `MapQuizView(category:)` for any category (it does) — no routing change needed
  beyond verifying it.
- Confirm `HomeQuizMode.mapQuiz.supportsNew == true` so the New (learning) pile
  appears for the new categories.
- Ensure pile picker, counts, and disabled-state behave for the new categories.

## Acceptance Criteria
1. Home shows a **Map** mode row under Rivers, Mountains, and Seas, in addition
   to their existing modes; countries unchanged.
2. Tapping Map for a category with both new and pending cards routes through the
   pile picker; new-only and pending-only route directly to the learning / quiz
   views respectively, for the correct category.
3. The launched map quiz/learning is for the selected category (rivers /
   mountains / seas), not countries.
4. App builds, installs, and launches without crashing; the new rows render.
5. Full suite green.

## Visual Verification
On the Home screen, Rivers, Mountains, and Seas each display a Map mode row
(with new/pending count pills as applicable), matching the country layout.
Screenshot the Home screen and confirm the rows are present.
