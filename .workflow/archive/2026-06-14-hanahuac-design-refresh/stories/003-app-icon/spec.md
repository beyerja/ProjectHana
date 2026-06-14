# 003 — Designed app icon (1024×1024 PNG)

## Goal
Produce a real, designed 1024×1024 PNG app icon reflecting "one world" (stylized globe/world motif
in the pastel palette) and install it into `AppIcon.appiconset` with correct `Contents.json`.

## Approach
- Prefer the **Canva MCP** integration to design the mark. Its tools are deferred — discover them
  via ToolSearch (`select:<name>` or keyword queries) before calling. Export a 1024×1024 PNG.
- **Fallback (acceptable):** generate the icon programmatically — an SVG rendered to PNG via on-system
  tools (`sips`, `qlmanage`, or a SwiftUI `ImageRenderer` snapshot run as a tiny tool) at 1024×1024.
  Must be a flat, full-bleed, opaque icon (no alpha/rounded corners — iOS masks it).
- Motif: stylized globe / "one world" using the palette (terracotta/coral + sage + cream).

## Scope / Files
- `ProjectHana/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1024×1024).
- Update `AppIcon.appiconset/Contents.json` to reference the filename for the universal 1024 slot.

## Acceptance Criteria
- [ ] A real 1024×1024 PNG (opaque, no alpha) is committed in AppIcon.appiconset.
- [ ] Contents.json references it; the project builds with no asset-catalog warnings about the icon.
- [ ] The icon renders on the home screen / app switcher (verified in simulator).
- [ ] Motif reflects "one world" in the pastel palette.
- [ ] Builds iOS + macOS; tests pass.

## Notes
- If Canva is impractical, the programmatic fallback fully satisfies the criteria — document which
  path was used in the story log.
- Depends on 002 for palette colors.
