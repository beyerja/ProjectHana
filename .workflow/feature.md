# Feature: Quiz Type Selection on Home Screen

## Goal

Reduce quiz start friction from 3 taps to 1–2 taps by surfacing all quiz modes directly on the home screen, eliminating the intermediate CategoryDetailView, LearningModePickerView, and QuizModePickerView screens.

## Current Flow (3 taps for Countries)

```
HomeView → "Countries" → CategoryDetailView → "New" → LearningModePickerView → "Map Quiz" → quiz
HomeView → "Countries" → CategoryDetailView → "Pending" → QuizModePickerView → "Map Tap" → quiz
```

Rivers / Mountains / Seas are 2 taps (no mode picker), but still route through CategoryDetailView.

## New Flow

**1 tap** when only one pile (new or pending) has cards for that quiz mode:
```
HomeView → tap quiz-mode button → quiz starts immediately
```

**2 taps** when both new and pending piles have cards for that quiz mode:
```
HomeView → tap quiz-mode button → PilePickerView → quiz starts
```

## Quiz Modes per Category

**Countries** (4 modes):
| Mode | New pile | Pending pile |
|------|----------|--------------|
| Map Quiz | MapLearningQuizView | MapQuizView |
| Multiple Choice | LearningQuizView | MultipleChoiceQuizView |
| Type Capital | — (not applicable) | CapitalQuizView(.capitalOfCountry) |
| Name Country | — (not applicable) | CapitalQuizView(.countryOfCapital) |

**Rivers / Mountains / Seas** (1 mode each):
| Mode | New pile | Pending pile |
|------|----------|--------------|
| Multiple Choice | LearningQuizView | MultipleChoiceQuizView |

## Home Screen UI

Replace the 2×2 category grid with a list of category sections. Each section:
- Category header (icon + name)
- Vertical list of quiz-mode buttons for that category

Each quiz-mode button shows:
- Mode name and icon
- Small inline count labels: "New: N" and/or "Pending: N" where N > 0
- Disabled / greyed if no cards exist for that mode in either pile
- "Type Capital" and "Name Country" buttons are greyed if no pending cards

### Example layout (Countries, 5 new + 3 pending):

```
🌍 Countries
  [Map Quiz]         New: 5  Pending: 3
  [Multiple Choice]  New: 5  Pending: 3
  [Type Capital]            Pending: 3
  [Name Country]            Pending: 3

🌊 Rivers
  [Multiple Choice]  New: 2

⛰ Mountains
  [Multiple Choice]  (greyed — nothing to study)

🌊 Seas
  [Multiple Choice]  Pending: 1
```

## PilePickerView

Shown only when both new and pending piles are non-empty for the tapped quiz mode.

- Title: the quiz mode name (e.g. "Map Quiz")
- Two buttons: "New — N cards" and "Pending — N cards"
- Tapping either navigates directly to the appropriate quiz view

## Navigation Destination Mapping

| Mode | Pile | Destination |
|------|------|-------------|
| Map Quiz (Country) | New | MapLearningQuizView(cards, category: .country) |
| Map Quiz (Country) | Pending | MapQuizView(category: .country) |
| Multiple Choice (Country) | New | LearningQuizView(cards, category: .country) |
| Multiple Choice (Country) | Pending | MultipleChoiceQuizView(category: .country) |
| Type Capital (Country) | Pending only | CapitalQuizView(mode: .capitalOfCountry) |
| Name Country (Country) | Pending only | CapitalQuizView(mode: .countryOfCapital) |
| Multiple Choice (River/Mountain/Sea) | New | LearningQuizView(cards, category: .X) |
| Multiple Choice (River/Mountain/Sea) | Pending | MultipleChoiceQuizView(category: .X) |

## Files to Create / Modify

- `Views/Home/HomeView.swift` — rewrite layout; embed navigation logic
- `Views/Home/PilePickerView.swift` — new view (new vs pending chooser)
- `Views/Home/CategoryDetailView.swift` — delete (replaced by HomeView)
- `Views/Quiz/LearningModePickerView.swift` — delete (replaced by HomeView)
- `Views/Quiz/QuizModePickerView.swift` — delete (replaced by HomeView)

## Acceptance Criteria

1. Home screen shows quiz-mode buttons for all categories with new/pending counts.
2. Tapping a quiz button with only one non-empty pile starts the quiz in 1 tap.
3. Tapping a quiz button with both piles non-empty shows PilePickerView; tapping there starts the quiz (2 taps total from home).
4. Buttons for modes with zero cards in both piles are disabled/greyed.
5. Type Capital and Name Country buttons are absent or greyed when no pending cards.
6. CategoryDetailView, LearningModePickerView, and QuizModePickerView are removed.
7. Settings (gear) and Stats links remain accessible from home.

## Out of Scope

- Changing quiz view logic or SRS behaviour
- Adding new quiz modes
- Onboarding / empty-state screens
