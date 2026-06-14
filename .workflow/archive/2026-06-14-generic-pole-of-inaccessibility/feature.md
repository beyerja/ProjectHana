# Feature: Generic Pole-of-Inaccessibility Pin Placement for All Countries

## Goal
Map quiz pins (the `lat`/`lon` fields in `countries.json`) must always appear inside the
country's boundary polygon. Some countries (confirmed: Norway, Sweden) have pins that fall
outside their border polygons — because the stored coordinates are hand-tuned centroid
guesses that do not guarantee point-in-polygon containment for countries with complex
coastlines (Norway's fjords) or narrow profiles (Sweden).

The fix must be **generic**: implement a pole-of-inaccessibility (visual center) algorithm
that, given a country's border polygon(s) from `country-borders.json`, computes a point
guaranteed to be inside the polygon. This replaces the static hardcoded lat/lon values
with a computed value (computed at app startup, cached) so ALL countries benefit
automatically — including any future ones added to the dataset.

No country should ever need a manually curated pin position. The algorithm must handle all
countries correctly by construction.

## Investigation
- Norway pin (lat=64.5, lon=17.9) — outside all 4 border rings in country-borders.json
- Sweden pin (lat=62.2, lon=17.7) — outside the single border ring
- Root cause: simple centroid guesses do not guarantee containment for complex shapes
- PR #57 (hardcoded fixes for Norway/Sweden only) was closed without merging

## Approach
Implement a **pole of inaccessibility** algorithm in Swift:
- For each country, select the largest ring in country-borders.json as the mainland polygon
- Apply an iterative cell-based approximation (Mapbox polylabel-style) or a simpler but
  correct fallback: binary-search the polygon's bounding box for a point with maximum
  distance to the nearest edge (sampling-based approach practical for Swift/on-device use)
- Cache the result so it is computed once at startup
- The `Country.lat`/`Country.lon` fields can remain in countries.json as display fallbacks,
  but the map quiz must use the computed pole-of-inaccessibility coordinate for pin placement

## Acceptance Criteria
- [ ] A `PoleLabelCalculator` (or equivalent) Swift type computes a guaranteed-interior point for any polygon ring
- [ ] Every country in countries.json whose id has a matching entry in country-borders.json gets a computed pin coordinate, verified to be inside the polygon via PIP
- [ ] A unit test verifies that ALL countries with border data have a computed pin that passes PIP — not just Norway and Sweden
- [ ] The map quiz uses the computed coordinate (not the raw lat/lon from countries.json) for pin placement
- [ ] App builds and all existing tests pass
- [ ] Norway and Sweden (and all other countries with complex borders) pass the PIP test automatically without any hardcoded coordinate

## Constraints
- The algorithm must be implemented in Swift and work on-device (no network, no pre-computation step)
- The solution must be generic — zero hardcoded country-specific coordinates
- Changing countries.json raw lat/lon is optional (they can remain as centroid fallbacks for non-map use cases)
- The border polygon data in country-borders.json must not be changed
