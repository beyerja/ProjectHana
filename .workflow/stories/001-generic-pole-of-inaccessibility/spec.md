# Story 001: Generic Pole-of-Inaccessibility Pin Placement

## Title
Implement generic pole-of-inaccessibility algorithm so every country's map pin is guaranteed inside its border polygon

## Goal
Replace the static lat/lon centroid guesses (which fail for Norway, Sweden, and potentially
other countries with complex borders) with a computed pole-of-inaccessibility coordinate.
The algorithm must be generic: it takes any polygon ring and returns a point guaranteed to
be inside it, with no per-country hardcoding.

## Acceptance Criteria
- [ ] A new Swift type (e.g. `PoleLabelCalculator` in `ProjectHana/Models/`) computes the pole of inaccessibility for a given `[CLLocationCoordinate2D]` polygon ring
- [ ] A new `CountryPinCoordinateProvider` (or equivalent) uses `CountryBorderLoader` + `PoleLabelCalculator` to return the best pin coordinate for any country id, falling back to the country's raw lat/lon if no border data is available
- [ ] `MapQuizView` (or the annotation placement code) uses `CountryPinCoordinateProvider` instead of `country.lat`/`country.lon` for pin placement
- [ ] A unit test verifies that for EVERY country that has an entry in `country-borders.json`, the computed pin coordinate passes a point-in-polygon test against its largest ring
- [ ] Norway and Sweden (the known failures) both pass the PIP test with the computed coordinate
- [ ] All existing tests continue to pass (`just test` succeeds)
- [ ] App builds without warnings

## Technical Notes

### Algorithm: Pole of Inaccessibility (sampling-based)
A practical Swift implementation for on-device use:
1. Compute the polygon's axis-aligned bounding box
2. Start with a grid of candidate cells covering the bounding box at a coarse resolution
3. For each cell center that is inside the polygon (PIP test), compute its distance to the nearest polygon edge
4. Keep the cell with maximum distance as the current best
5. Optionally refine: subdivide the best cell and repeat until precision is adequate (e.g. < 0.1 degree)
6. Return the best cell center

A simpler but correct alternative (if performance is acceptable):
- Sample a dense grid (e.g. 50x50) over the bounding box
- Filter to points that are inside the polygon (PIP)
- For each interior point, compute min distance to any polygon edge
- Return the point with maximum min-distance

This is O(n*m) where n=grid cells, m=polygon vertices. For typical country borders
(~50–2000 vertices) and a 50x50 grid (2500 cells), this is fast enough for startup.

### Files to create
- `ProjectHana/Models/PoleLabelCalculator.swift` — the algorithm
- `ProjectHana/Models/CountryPinCoordinateProvider.swift` — combines border data + algorithm

### Files to edit
- `ProjectHana/Views/Quiz/MapQuiz/MapQuizView.swift` (or `MapQuizRegionHelper.swift`) — use provider for pin coordinates
- `ProjectHanaTests/MapQuizRegionHelperTests.swift` — replace the Norway/Sweden-only PIP tests with an all-countries PIP test

### Polygon selection
For countries with multiple rings (e.g. Norway has mainland + islands), select the ring
with the most vertices as the mainland polygon. This is the same heuristic used in PR #57's tests.

### Point-in-polygon
Use the ray-casting algorithm (already present in the test file from PR #57 — can be
promoted to a shared utility or kept inline).
