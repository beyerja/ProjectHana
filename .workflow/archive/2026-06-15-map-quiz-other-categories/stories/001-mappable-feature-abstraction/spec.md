# Story 001 — Generalize the map quiz over a mappable-feature abstraction

## Title
Abstract the Country-typed map quiz/learning code over a `MappableFeature` protocol

## Goal
Introduce a protocol (e.g. `MappableFeature`) that the map quiz, map learning,
sessions, and region helper are written against — instead of the concrete
`Country` type — so future stories can plug in rivers, mountains, and seas
without further refactoring. This story is a **behaviour-preserving refactor**:
the country map quiz and country map learning must look and behave exactly as
before. No new categories are wired up here.

## Scope / design notes
- Define a `MappableFeature` protocol capturing what the map UI needs:
  - `id: String`
  - `localizedName(for:) -> String`
  - pin coordinate (`CLLocationCoordinate2D`)
  - optional border rings (`[[CLLocationCoordinate2D]]?`)
  - optional line endpoints for rivers (`(start, end)?` → nil for non-rivers)
- Make `Country` conform. Pin coordinate for countries continues to come from
  `CountryPinCoordinateProvider` (pole of inaccessibility) and rings from
  `CountryBorderLoader`. Do NOT regress the pole-of-inaccessibility pin.
- Generalize `MapQuizSession`, `MapLearningSession`, and `makeQuizAnnotations`
  (region helper) to operate on `[any MappableFeature]` / the protocol rather
  than `[Country]`. Keep method names usable (a `handleTap(id:)` is fine).
- Generalize `MapQuizView` and `MapLearningQuizView` to render pins + optional
  polygon overlays from the feature, keyed by `category`. Country still uses
  `.imagery` satellite base + `MapPolygon` overlays. (Polyline rendering for
  rivers is added in story 002; design the view so it can render a line when a
  feature provides endpoints, even if no feature does yet.)
- Generalize the border lookup so country rings still load from
  `CountryBorderLoader`. A category→borders indirection is acceptable.
- Keep `AnswerState` and its `polygonFillColor(for:)` semantics.

## Acceptance Criteria
1. A `MappableFeature` protocol exists; `Country` conforms.
2. `MapQuizSession`, `MapLearningSession`, and the region/annotation helper are
   expressed in terms of the protocol (or a generic), not the concrete
   `Country` type, while the country code path is unchanged in behaviour.
3. `MapQuizView` / `MapLearningQuizView` render from the abstraction and still
   show the country satellite map with border polygons and pole pins.
4. All existing tests pass (`MapLearningTests`, `MapQuizRegionHelperTests`,
   `QuizLogicTests`, etc.), updated only as needed to construct features via the
   protocol — country behaviour assertions unchanged.
5. `just generate` (if files added) + `just test` are green.

## Visual Verification
Country map quiz and country map learning render identically to before
(satellite base, border polygons, pole-of-inaccessibility pins).
