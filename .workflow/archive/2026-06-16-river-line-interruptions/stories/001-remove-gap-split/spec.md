# 001 — Remove gap-split so rivers render continuous

## Goal
Stop continuous rivers (esp. the Lena and other Siberian rivers) from rendering as
gapped/dashed broken lines, by removing the `GAP_SPLIT_DEG` shatter step from
`scripts/generate-river-paths.py`, regenerating `river-paths.json`, and replacing the
test that encoded the wrong invariant.

## Acceptance Criteria
- `gap_split()`, its call site in `build_rivers()`, and `GAP_SPLIT_DEG` are removed;
  docstring/comment references to gap-splitting are removed. `JOIN_TOLERANCE = 0.05`
  unchanged.
- `python3 scripts/generate-river-paths.py` (verify mode) reports 32/32 matched and the
  expected parts-count drop; `--write` regenerates `Hanahuac/Resources/river-paths.json`.
- Lena collapses to ~1 continuous part; mean parts/river ≈ 2.0.
- `testNoRiverPartHasLongStraightJump` is replaced by tests asserting:
  no false cross-piece joins, a sane parts-per-river bound, and Lena continuity.
- Other river tests still pass (32/32 coverage, pin-on-path, Amazon stem,
  ≥3-vertex parts, Nile detailed centerline).
- `just lint` and `just test` are clean.
- Visual matplotlib render confirms continuity and no teleport lines.
