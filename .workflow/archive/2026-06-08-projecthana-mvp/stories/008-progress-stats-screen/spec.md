# Story 008: Progress & Stats Screen

## Title
Build the progress screen showing mastery, streaks, and per-category card breakdowns

## Goal
Give the user a clear picture of their learning progress: total cards by mastery level, daily
streak, and per-category statistics — all derived from SwiftData state.

## Acceptance Criteria
- [ ] `ProgressView` (not to conflict with SwiftUI's built-in; name it `StatsView`) is reachable
      from `HomeView` via the "Progress" navigation link
- [ ] Displays: "Total cards reviewed", "Due today", "Streak: N days"
- [ ] Displays a per-category breakdown table (Countries / Rivers / Mountains / Seas) showing
      count in each mastery tier: New (grey), Learning (yellow), Review (blue), Mastered (green)
- [ ] Mastery tiers defined as: New = repetitionCount 0; Learning = repetitionCount 1–2;
      Review = repetitionCount 3–4; Mastered = repetitionCount >= 5 AND easeFactor >= 2.0
- [ ] Colour-coded mastery badges use SwiftUI foreground/background colours matching the tiers
- [ ] Streak is computed as consecutive calendar days (user's local timezone) on which at least
      one card was reviewed; stored as an Int in UserDefaults (updated after each session)
- [ ] Screen updates reactively when returning from a quiz session without requiring app relaunch
- [ ] Both light and dark mode render correctly
- [ ] Unit tests cover: mastery tier classification function, streak increment logic
