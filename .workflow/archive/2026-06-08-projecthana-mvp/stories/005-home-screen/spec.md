# Story 005: Home Screen

## Title
Build the home screen showing due-card count, category filters, and navigation to quiz/stats

## Goal
Give the user a clear entry point: see how many cards are due today, choose a category, and
navigate into a quiz session or the progress screen.

## Acceptance Criteria
- [ ] `HomeView` is the root view; it shows the app name "ProjectHana" and a prominent "Due today: N"
      count that reflects actual `CardStore.dueCards` count
- [ ] Four category buttons are displayed: Countries, Rivers, Mountains, Seas — tapping one opens
      a quiz session filtered to that category (navigation to a placeholder if quiz not yet built)
- [ ] An "All Categories" button starts a session with no filter
- [ ] A "Progress" navigation link opens the stats screen (placeholder if not yet built)
- [ ] The due count updates without relaunch when cards are reviewed (reactive via `@Observable`)
- [ ] Both light and dark mode render without layout issues (verified via SwiftUI preview)
- [ ] Dynamic Type: all text uses system fonts or `.body`/`.title` style so it scales correctly
- [ ] App launches to `HomeView` within 2 seconds on iPhone 15 simulator
