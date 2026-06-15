# Story 001 — Refactor MappableFeature to a multi-point river line path

## Goal
Replace the two-endpoint `lineEndpoints` abstraction on `MappableFeature` with a real
multi-point line path so rivers can be drawn along their actual course. This story
introduces the abstraction and a `RiverPathLoader` that initially returns empty (stub),
so every river gracefully falls back to the straight source→mouth line — exactly the
mountains pin-only graceful-degradation pattern. The build stays green and the visible
behaviour is unchanged (still straight lines) until story 002 supplies the data.

## Acceptance Criteria
- [ ] `MappableFeature` exposes a multi-point line path (e.g.
      `var linePath: [[CLLocationCoordinate2D]]? { get }` — a list of polyline parts to
      support multi-part rivers), replacing `lineEndpoints`.
- [ ] `River` returns its sourced path from `RiverPathLoader.shared[id]` when present,
      otherwise falls back to a single straight source→mouth part. Country, Sea,
      MountainRange return `nil`.
- [ ] A new `RiverPathLoader` (mirroring `BorderLoader`) loads `river-paths.json`
      `[{"id": "<id>", "path": [[lon,lat],...]}]` or multi-part
      `[{"id": "<id>", "parts": [[[lon,lat],...],...]}]` into `id → [[CLLocationCoordinate2D]]`.
      It returns an empty dictionary when the resource is absent (this story ships no
      JSON yet) so all rivers fall back.
- [ ] `MapFeatureRendering.featureOverlays` draws each part of `linePath` as a
      `MapPolyline`, keeping the existing answer-state stroke colours. The straight
      fallback part is densified for smoothness as before.
- [ ] `River.pinCoordinate` is unchanged in this story (source/mouth midpoint); pin-on-path
      is story 003.
- [ ] Existing tests updated for the `lineEndpoints` → `linePath` change; all
      `just test` pass. Add a test that a river with no path data falls back to a
      single straight part whose endpoints are source and mouth.

## Notes
- Grep for existing `extension River`, `extension MappableFeature`, and any
  `lineEndpoints` usages across `Hanahuac/` before editing; update every call site.
- No new resource file added in this story → `just generate` only needed if a new Swift
  file (`RiverPathLoader.swift`) is added as its own file. Run it after adding the file.
