# 004 — SwiftUI-drawn in-app logo mark

## Goal
Create a scalable, vector SwiftUI logo mark (no external asset dependency) consistent with the app
icon's "one world" motif, suitable for use on the redesigned home landing.

## Scope / Files
- New `ProjectHana/Views/Components/LogoMark.swift` (a reusable `View`, size-parameterized).
- Drawn with SwiftUI primitives / `Shape` / `Canvas` using the Theme palette (no images).
- Should visually echo the app icon (003) so identity is cohesive.
- Provide a SwiftUI `#Preview`.

## Acceptance Criteria
- [ ] A reusable SwiftUI `LogoMark` view exists, drawn purely with SwiftUI (no asset/image files).
- [ ] It scales cleanly at different sizes and uses palette colors.
- [ ] It echoes the app-icon motif (one world / globe).
- [ ] Builds iOS + macOS; tests pass. (Consumed on home in 005.)

## Notes
- Depends on 002 (palette) and is motif-consistent with 003 (icon).
