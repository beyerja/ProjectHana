# Feature: Map quiz & map learning for rivers, mountains, seas

## Goal

Today a **map quiz** and **map learning mode** exist only for the `country`
category. Extend both to the other three categories — **rivers**, **mountains**,
**seas** — so every category offers the full set of modes (map tap quiz +
map learning), matching countries. Do **not** change existing country behaviour
or the `country-borders.json` data.

## Background (codebase)

- Map quiz code lives in `Hanahuac/Views/Quiz/MapQuiz/`:
  `MapQuizView`, `MapQuizSession`, `MapLearningQuizView`, `MapLearningSession`,
  `MapQuizRegionHelper`, `QuizSummaryView`.
- These are currently hardcoded to `Country`: typed to `Country`, use
  `CountryBorderLoader` + `CountryPinCoordinateProvider`, render satellite
  imagery (`.imagery`) with `MapPolygon` border overlays, and load
  `GeographyDataLoader.shared.countries`.
- `MapQuizView(category:)` and `MapLearningQuizView(newCards:category:)` already
  *accept* a `category`, and `HomeView.directQuizView` already routes
  `.mapQuiz` for any category to them — but the views ignore the category for
  data and only `HomeView`'s `categorySections` exposes `.mapQuiz` for
  `.country`. The other three categories list only `[.multipleChoice]`.
- Models: `Country` (point + border rings via JSON), `River`
  (sourceLat/Lon + mouthLat/Lon = two endpoints / a line), `MountainRange`
  (single lat/lon + peak/elevation), `Sea` (single lat/lon). All have localized
  en/fr/de/esMX names and clean string `id`s. All four categories are already
  seeded into `CardStore` (`seedIfNeeded`).
- Precedent — country borders pipeline (archived
  `.workflow/archive/2026-06-11-country-borders/`): downloaded Natural Earth
  110m admin-0 GeoJSON, processed into compact `country-borders.json` =
  `[{"id","rings":[[[lon,lat],...]]}]`, bundled in `Resources/`, wired into
  `project.yml`, loaded by `CountryBorderLoader` into
  `[String: [[CLLocationCoordinate2D]]]`, rendered as `MapPolygon`.

## Finalized decisions

1. **Scope:** all three categories — rivers, mountains, seas.
2. **Mechanic:** identical to countries — correct pin among distractor pins,
   prompt "tap the named feature." Same SM-2 / dual-penalty / 3-correct
   graduation behaviour. Both the **pending** (due) map quiz AND the **new**
   (learning) map mode for each category.
3. **Rivers → line + midpoint pin.** Render the river as a drawn polyline
   (straight / great-circle between source and mouth — only the two endpoints
   exist) with a tappable pin at the line midpoint. No river polygon.
4. **Seas → polygon overlay + pin.** Source from Natural Earth marine polygons
   (`ne_*_geography_marine_polys` / IHO Limits of Oceans and Seas). Process into
   bundled `sea-borders.json` of the same `{"id","rings"}` shape, keyed to
   `seas.json` ids, matched by name. Pin = the explicit `lat`/`lon` already in
   `seas.json`. 20 seas — manually verifiable.
5. **Mountains → polygon overlay + pin, with pin-only fallback.** Source range
   polygons (GMBA Mountain Inventory or Natural Earth region polygons), process
   into bundled `mountain-borders.json` (`{"id","rings"}`), match to
   `mountains.json` ids by name. Where no polygon can be confidently matched,
   fall back to pin-only for that range. Pin = the explicit `lat`/`lon` in
   `mountains.json`. 23 ranges — manually verifiable.
6. **Map style + geometry:** pins-on-satellite (`.imagery`) base for all, same
   as countries.
7. **Out of scope:** no change to the country map quiz behaviour or
   `country-borders.json`. No new app-facing data fields beyond the new border
   JSON files.

## Engineering approach

- Generalize the `Country`-typed map quiz over a **mappable-feature protocol**
  (id, localized name, pin coordinate, optional border rings, optional line
  endpoints), driven by `category`, so pins/polygons/lines render per category.
  Design the actual abstraction against the real code.
- Add `MapPolyline` (MapKit polyline overlay) rendering for rivers; existing
  code only does `MapPolygon`.
- Reuse `CountryBorderLoader`'s loading pattern for the new sea/mountain border
  loaders (or generalize it). Pin placement: seas/mountains use their JSON
  lat/lon directly; rivers use the line midpoint; countries keep the existing
  pole-of-inaccessibility provider.
- Wire new `Resources/*.json` into `project.yml` and regenerate
  (`just generate`) — never hand-edit the pbxproj.

## Acceptance Criteria

1. From the Home screen, the **Rivers**, **Mountains**, and **Seas** categories
   each expose the **Map** quiz mode (the `.mapQuiz` row), alongside their
   existing modes. (Country map quiz unchanged.)
2. Selecting the Map mode for a category with **due** cards launches a map quiz
   that quizzes that category's features (rivers / mountains / seas), not
   countries — the prompt names a feature of the chosen category and tapping the
   correct pin scores correct.
3. Selecting the Map mode for a category with **new** cards launches the map
   **learning** mode for that category, with the same 3-correct graduation,
   streak display, and active-set persistence as countries.
4. **Rivers** render as a drawn line between source and mouth with a tappable
   pin at the midpoint; correct/incorrect feedback highlights the line/pin.
5. **Seas** render a polygon overlay (from bundled `sea-borders.json`) plus a
   pin; the overlay highlights on answer. All 20 seas have a matched polygon
   (verify by name match coverage).
6. **Mountains** render a polygon overlay (from bundled `mountain-borders.json`)
   plus a pin where a polygon is matched, and fall back to pin-only where no
   polygon is confidently matched — without crashing or showing a wrong polygon.
7. The existing **country** map quiz and map learning behaviour are byte-for-byte
   unchanged in mechanic and appearance (regression: country tests still pass).
8. New border JSON files are bundled via `project.yml`/xcodegen and load at
   runtime; loaders return the expected entry counts.
9. Test coverage exists for the new categories: feature/region annotation
   helper generalization, polygon matching + mountain pin-only fallback, river
   midpoint/line geometry, and session mechanics per category. Full suite green
   in CI.

## Visual Verification

The app launches without crashing; the Home screen shows a **Map** mode row
under Rivers, Mountains, and Seas (in addition to countries). Deeper map screens
are verified via unit tests + compilation into the shipped bundle, since the
toolset cannot tap through navigation.
