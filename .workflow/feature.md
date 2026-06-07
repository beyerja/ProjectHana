# Feature: ProjectHana — Personalized Geography Learning App (MVP)

## Goal

Build a native iOS/macOS app that teaches world geography (countries, capitals, major rivers, seas,
mountain ranges) through map-based interactive quizzes driven by a spaced-repetition scheduler
(SM-2 algorithm). Users drill geography facts visually and the scheduler surfaces cards at optimal
intervals so knowledge is retained long-term.

## Architecture Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Platform | iOS 17+ (iPhone + iPad), macOS 14+ via Mac Catalyst | iOS 17 covers ~85 % of active devices (2024); gives access to SwiftData, MapKit improvements, and TipKit without shims |
| UI framework | SwiftUI | Declarative, cross-platform (iOS + Catalyst), aligns with Apple-first dependency constraint |
| Persistence | SwiftData | Zero-dependency ORM, replaces Core Data boilerplate, available iOS 17+ |
| Maps | MapKit (SwiftUI `Map` view) | First-party, no external dependency |
| Spaced repetition | SM-2, implemented from scratch in Swift | No external dependency; SM-2 is public-domain and simple enough to own |
| Dependencies | None external (zero third-party packages) | User requirement |
| Bundle ID | com.projecthana.app | Placeholder; user may change before App Store submission |
| CI/CD | GitHub Actions — build + test on every push to main and on PRs | User requirement |
| Testing | XCTest unit tests for SM-2 logic and data model; UI tests for critical flows | Balance quality vs. workflow speed |

## Acceptance Criteria

### Content & Data
- [ ] App ships with a bundled JSON dataset covering all 195 UN-recognised countries, each entry containing: name, ISO-3166-1 alpha-2 code, capital city, continent, and approximate centroid coordinates (lat/lon)
- [ ] App ships with a bundled JSON dataset covering at least 30 major rivers, each with: name, continent(s), approximate source and mouth coordinates
- [ ] App ships with a bundled JSON dataset covering at least 20 major mountain ranges, each with: name, continent, approximate centroid coordinates, highest peak name and elevation (metres)
- [ ] App ships with a bundled JSON dataset covering at least 15 major seas/oceans, each with: name, approximate centroid coordinates

### Quiz Engine
- [ ] Five quiz modes are available: (1) Tap the country on the map, (2) Name the capital given the country, (3) Name the country given the capital, (4) Identify the river/mountain/sea shown on the map, (5) Multiple-choice (4 options) for any fact
- [ ] Each quiz session presents questions in SM-2 priority order (overdue cards first, then new cards)
- [ ] After answering, the user rates recall difficulty on a 0–5 scale (or the app infers a binary correct/incorrect and maps it to a quality score); the SM-2 scheduler updates the card's next review date accordingly
- [ ] The app prevents reviewing a card before its scheduled date (within the same session) unless the user forces a re-drill
- [ ] Quiz sessions can be filtered by category (countries, rivers, mountains, seas) and by continent

### Spaced Repetition
- [ ] SM-2 algorithm is implemented correctly: initial interval 1 day, second interval 6 days, subsequent intervals = previous interval × ease factor; ease factor starts at 2.5, adjusts by quality score; minimum ease factor 1.3
- [ ] Card metadata (repetition count, ease factor, interval, next review date, last quality score) is persisted between app launches
- [ ] A "due today" count is displayed on the home screen

### Map Interaction
- [ ] Maps are rendered using MapKit; country/region highlighting uses SwiftUI overlays or MapKit annotations
- [ ] Tapping an incorrect region shows visual feedback (wrong colour) before revealing the correct region
- [ ] Tapping the correct region shows a success animation

### Progress & Stats
- [ ] A progress screen shows: total cards seen, total due today, streak (consecutive days with at least one review), per-category breakdown (countries / rivers / mountains / seas)
- [ ] Cards are colour-coded by mastery level: new (grey), learning (yellow), review (blue), mastered (green) — based on repetition count and ease factor thresholds

### UX / Polish
- [ ] App launches to a home screen within 2 seconds on an iPhone 15 (or simulator equivalent)
- [ ] App supports both light and dark mode
- [ ] App supports Dynamic Type (text scales with system font size setting)
- [ ] No crash occurs during a full 20-question quiz session

### CI/CD
- [ ] GitHub Actions workflow runs `xcodebuild test` on push to `main` and on pull requests
- [ ] Build and test pass on the CI runner (macOS-latest with Xcode 16)

## Constraints

- Zero external Swift Package dependencies — use only Apple frameworks (SwiftUI, SwiftData, MapKit, Foundation, XCTest)
- Minimum deployment: iOS 17.0, macOS 14.0 (Sonoma) via Catalyst
- All geography data bundled at build time (no network calls required to use the app)
- App must compile with Swift 5.10+ / Xcode 16+
- No App Store submission in scope (no provisioning profile or team ID required for MVP)

## Out of Scope

- User accounts, cloud sync, or iCloud backup
- Audio pronunciation of place names
- Custom quiz creation by the user
- Offline map tile downloads (MapKit standard tiles suffice)
- Localisation beyond English
- tvOS, watchOS, or visionOS targets
- App Store submission and signing
- Animations beyond basic SwiftUI transitions and colour feedback
- Social / sharing features
