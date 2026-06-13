# Story 003: Map Learning UI (Mode Picker for New Country Cards)

## Title
Offer map-quiz and MCQ mode choices when tapping the New tile for the Countries category

## Goal
`CategoryDetailView` currently routes the "New" tile directly to `LearningQuizView` (MCQ) for all categories. For the `.country` category only, it must instead present a mode-picker (or adapted `QuizModePickerView`) that lets the user choose Map or MCQ, then route accordingly: MCQ → existing `LearningQuizView`, Map → new `MapLearningQuizView` backed by `MapLearningSession`.

## Background
- `CategoryDetailView.newTile` always navigates to `LearningQuizView`. The `.country` case needs a branch.
- `QuizModePickerView` exists for the Pending tile; it can be adapted or reused for the New path, or a new lightweight picker can be created.
- `MapQuizView` + `MapQuizSession` power the existing Pending map path; the new view (`MapLearningQuizView`) should reuse the map UI but drive `MapLearningSession` instead.
- All other categories (river, mountain, sea) continue to go directly to `LearningQuizView` — no change.

## Acceptance Criteria
- [ ] Tapping the "New" tile for `.country` presents a mode picker with at least two options: "Map" and "MCQ" (or equivalent labels matching the existing app style).
- [ ] Choosing MCQ opens `LearningQuizView` (existing behavior, unchanged).
- [ ] Choosing Map opens a view (`MapLearningQuizView` or equivalent) that drives `MapLearningSession` and shows the same map interaction as `MapQuizView`.
- [ ] Tapping "New" for any other category (river, mountain, sea) still goes directly to `LearningQuizView` — no picker is shown.
- [ ] The map learning view shows appropriate completion/summary state when the session finishes (all cards graduated).
- [ ] The app builds without warnings.
- [ ] No existing Pending-tile navigation is broken.
