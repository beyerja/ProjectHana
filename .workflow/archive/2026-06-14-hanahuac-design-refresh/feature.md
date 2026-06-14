# Feature: App Design Refresh — "Hanahuac"

## Goal
Transform the app from a generic, system-default look into a distinctive, warm, pastel-themed
geography learning experience. This covers a full visual identity: a real product name, a logo
and app icon, a cohesive pastel color system, a redesigned home landing, and supporting polish
(typography, card styling, iconography, micro-animations, empty states).

The app is currently named "ProjectHana" (a placeholder) and uses only system defaults: empty
AccentColor, an empty AppIcon, inline `.blue`/`.cyan`/`.brown`/`.teal` colors, and `.quaternary`
card backgrounds. The home screen opens straight into a plain scroll list with no identity.

## Naming Decision
**New name: `Hanahuac`** (pronounced *ha-na-wak*), meaning **"One World"**.
- Korean `하나 (hana)` = *one* (preserves the original "Hana" heritage — the first agentic project).
- Nahuatl `Anahuac` = *the world / land surrounded by water* — a literal geographic term.
- Rename applies **everywhere**: display name, navigation title, Xcode project/target/scheme,
  bundle identifier (`com.projecthana.app` → `com.hanahuac.app`), `project.yml`, README, and any
  user-facing or localized strings. Update all 4 localizations (en/fr/de/es-MX).

## Color System (light mode only)
Build a **central, reusable Theme/palette abstraction** (e.g. `Theme.swift` with a `Palette`)
so colors are defined once and easy to tweak. No dark-mode variants required. Use warm pastels
that nod to the Korean + Mexican (Nahuatl) heritage. Starting palette (refine for WCAG contrast):
- Canvas / background: warm cream (~#FBF7F0)
- Card / surface: white or soft sand (~#F4EEE4), with subtle depth (soft shadow / hairline border)
- Primary accent: soft terracotta/coral (~#E8A398) → drives AccentColor
- Secondary accent: sage green (~#9FC9B6)
- Category pastels: Countries=pastel sky (~#A8C0E8), Rivers=pastel aqua (~#9ED7DE),
  Mountains=pastel clay (~#C9A9A6), Seas=pastel teal (~#8FCFC9)
- Text: warm near-black (~#3A332E) primary, warm gray (~#8A8077) secondary
- State pills: "new" pastel green, "pending" pastel periwinkle/blue
Replace all hardcoded inline colors across the app with palette references.

## Logo & App Icon (option c — both)
- **App icon:** a real, designed 1024×1024 PNG installed into `AppIcon.appiconset`. Prefer the
  Canva MCP integration for the designed mark; a programmatic SVG/ImageRenderer fallback is
  acceptable. The icon should reflect "one world" — e.g. a stylized globe/world motif in the
  pastel palette. Update `Contents.json` accordingly.
- **In-app logo mark:** a SwiftUI-drawn logo (vector, scalable, no external asset dependency)
  used on the redesigned home landing — consistent with the app icon's motif.

## Redesigned Home Landing
Keep the existing navigation/data flow and quiz routing intact; restyle the landing only.
- Branded header area with the SwiftUI logo mark + "Hanahuac" wordmark (replaces the plain
  large nav title), on the pastel canvas.
- Restyle category sections and quiz-mode rows with the new palette, improved card depth,
  rounded friendly typography, and consistent iconography.
- Tasteful micro-animations/transitions (appearance, button press) — subtle, not distracting.
- Polish empty/disabled states (e.g. when no cards are due) so they look intentional.

## Acceptance Criteria
- [ ] App is renamed to **Hanahuac** everywhere: display name, nav title, Xcode project/target/
      scheme, bundle ID, `project.yml`, README, and all localized strings (en/fr/de/es-MX).
- [ ] A central Theme/palette abstraction exists; no view uses hardcoded ad-hoc colors anymore.
- [ ] The pastel palette is applied app-wide (home, quizzes, stats, settings) — light mode only.
- [ ] A real designed app icon (1024×1024 PNG) is present in `AppIcon.appiconset` and renders.
- [ ] A SwiftUI-drawn logo mark appears on the redesigned home landing.
- [ ] The home landing is visibly redesigned (branded header, restyled cards, polish) while all
      existing navigation and quiz flows still work.
- [ ] Typography is upgraded to a friendlier rounded style consistently.
- [ ] The project builds for iOS and macOS and all tests pass.

## Constraints
- SwiftUI only; **zero external dependencies**.
- iOS 17+ / macOS 14+ (Mac Catalyst). Maintain all 4 localizations.
- Light mode only — do not add dark-mode color sets.
- Do not change app logic, data models, scheduler, or quiz behavior — visual/identity only.
- Preserve accessibility: ensure pastel text/background combos meet reasonable contrast.

## Out of Scope
- Dark mode.
- New features, new quiz types, or changes to learning/scheduling logic.
- New localizations beyond the existing four.
- Backend/data changes.
