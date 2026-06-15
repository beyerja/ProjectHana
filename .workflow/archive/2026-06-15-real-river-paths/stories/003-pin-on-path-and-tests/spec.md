# Story 003 — Pin on the real path + path-fidelity tests + visual verification

## Goal
Finish the feature: move each matched river's tappable pin onto a vertex near the real
path midpoint (fallback rivers keep the source/mouth midpoint), add the path-fidelity
test coverage over the real bundled data, and confirm visually that rivers now render as
curved real-course lines.

## Acceptance Criteria
- [ ] `River.pinCoordinate` returns a vertex near the midpoint of the matched path (the
      vertex closest to the path's halfway point along its length, so the pin sits ON the
      river). When no path data exists, it falls back to the source/mouth midpoint
      (unchanged behaviour).
- [ ] Tests cover, over the real bundled data: every one of the 32 rivers either has a
      matched multi-point path (>2 vertices) OR is in a small documented fallback set;
      the fallback set is asserted explicitly so a regression in coverage is caught.
- [ ] A test asserts the pin coordinate of a matched river coincides with (is within a
      small epsilon of) one of its path vertices.
- [ ] A test asserts coordinate counts are sane (no path part has fewer than 2 vertices;
      matched rivers exceed 2).

## Visual Verification
After build+install to the simulator, launch the app and open the river map quiz / map
learning view. A representative river (Nile or Amazon) must render as a curved polyline
following the river's real course — clearly NOT a straight line between two points — and
its tappable pin must sit on that line. Capture a screenshot and confirm against this
criterion.

## Notes
- Grep for existing `pinCoordinate`/`linePath` declarations on `River` before editing.
- Determine the fallback set empirically from story 002's generated JSON (which rivers
  were omitted); encode it as the documented expected-fallback list in the test.
