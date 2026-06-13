# Stories: Quiz Type Selection on Home Screen

## Story 001 — Rewrite HomeView with per-category quiz-mode buttons
- **Dir**: `.workflow/stories/001-home-view-redesign`
- **Status**: pending

Replace the 2×2 category grid on HomeView with a vertical list of category sections. Each section shows the category header and quiz-mode buttons with inline new/pending card counts. Buttons are disabled when no cards exist for that mode in either pile.

**Quiz modes per category:**
- Countries: Map Quiz, Multiple Choice, Type Capital, Name Country
- Rivers / Mountains / Seas: Multiple Choice

**Each button shows:**
- Mode name + icon
- "New: N" label if new count > 0
- "Pending: N" label if pending count > 0
- Disabled/greyed if both counts are zero
- Type Capital / Name Country are greyed if no pending cards (they are pending-only modes)

**Files to change:**
- `Views/Home/HomeView.swift` — rewrite

**Acceptance criteria:**
- Home screen shows quiz-mode buttons for all categories
- New/pending counts visible on each button
- Buttons with zero cards are disabled

---

## Story 002 — PilePickerView and end-to-end navigation
- **Dir**: `.workflow/stories/002-navigation-pile-picker`
- **Status**: pending

Create `PilePickerView`. Wire navigation from HomeView quiz buttons:
- Only new cards → navigate directly to appropriate quiz view (1 tap)
- Only pending → navigate directly (1 tap)
- Both → navigate to PilePickerView, then to quiz (2 taps)

See `feature.md` navigation destination mapping table for exact view targets.

**Files to change:**
- `Views/Home/HomeView.swift` — add NavigationLink destinations
- `Views/Home/PilePickerView.swift` — new file

**Acceptance criteria:**
- 1-tap flow works for single-pile cases across all categories/modes
- 2-tap flow works (PilePickerView) when both piles are non-empty
- Correct quiz views are launched in all combinations

---

## Story 003 — Remove obsolete screens
- **Dir**: `.workflow/stories/003-cleanup`
- **Status**: pending

Delete CategoryDetailView, LearningModePickerView, and QuizModePickerView. Fix any dangling references.

**Files to delete:**
- `Views/Home/CategoryDetailView.swift`
- `Views/Quiz/LearningModePickerView.swift`
- `Views/Quiz/QuizModePickerView.swift`

**Acceptance criteria:**
- Project compiles without errors
- No references to deleted views remain
