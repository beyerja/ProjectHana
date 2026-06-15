# Story 002 — Rivers map quiz & learning (line + midpoint pin)

## Title
Add river support to the generalized map quiz: drawn line + midpoint pin

## Goal
Make `River` a `MappableFeature` so the map quiz and map learning modes work for
the rivers category. Rivers have only two endpoints (source, mouth) and no
polygon, so they render as a drawn line between the endpoints with a tappable
pin at the line midpoint.

## Scope / design notes
- `River` conforms to `MappableFeature`:
  - pin coordinate = midpoint of source→mouth (great-circle or straight midpoint
    is acceptable; keep it simple and deterministic).
  - border rings = nil.
  - line endpoints = (source, mouth).
- Add `MapPolyline` rendering to the generalized map views so a feature with
  line endpoints draws a line between them (countries/seas/mountains have no
  endpoints → no line). Correct/incorrect feedback should colour the line/pin
  consistently with the existing pin feedback.
- Wire the rivers category data into session construction: when category is
  `.river`, build sessions over `GeographyDataLoader.shared.rivers` mapped to
  features.
- No new bundled JSON files (endpoints already in `rivers.json`).

## Acceptance Criteria
1. `River` conforms to `MappableFeature`; its pin coordinate is the source/mouth
   midpoint and it exposes the two endpoints as a line.
2. The generalized map views render a polyline between a river's endpoints with a
   tappable pin at the midpoint.
3. A map quiz built for `.river` quizzes rivers (prompt names a river; tapping
   the correct river's pin scores correct) using the same mechanic as countries.
4. Map learning for `.river` graduates after 3 consecutive correct with streak
   display and active-set persistence, same as countries.
5. Tests cover river midpoint geometry, line endpoints, and a river session
   round-trip (correct/incorrect). Full suite green.

## Visual Verification
A rivers map quiz shows a line drawn across the map with a pin at its midpoint;
tapping pins gives correct/incorrect feedback. (Verified via unit tests +
compilation since the toolset cannot tap through navigation.)
