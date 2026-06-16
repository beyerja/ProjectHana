# Feature: River line interruptions (gapped/dashed rivers fix)

## Problem
On the map-learning / map-quiz `river` screen, several rivers — most visibly the
Lena and other Siberian rivers — render as gapped / dashed broken lines instead of
one continuous course.

## Root cause
`scripts/generate-river-paths.py` gained `GAP_SPLIT_DEG = 0.4` in #77. The
`gap_split()` step shatters a continuous river at Natural Earth's sparse-sampling
gaps: the Lena becomes 10–20 separate `parts`. `MapFeatureRendering.swift` draws one
`MapPolyline` per part, so those shards render as a gapped/dashed line.

## Fix (decided)
- Remove the gap-split step entirely: delete the `gap_split()` function, its call
  site in `build_rivers()`, and the `GAP_SPLIT_DEG` constant + its doc references.
- KEEP `JOIN_TOLERANCE = 0.05` unchanged — it correctly keeps genuinely-separate NE
  pieces apart; raising it caused the old teleport lines.
- Regenerate `Hanahuac/Resources/river-paths.json` via `--write`.
  Expected: Lena collapses to ~1 continuous part; mean parts/river drops ~2.5 → ~2.0;
  32/32 rivers still match; Amazon full stem preserved.

## Product decisions (from user — do NOT re-ask)
1. Within-segment coarse straight reaches that reappear after removing gap-split
   (worst ≈1.36° on the Lena): ACCEPT as-is. No smoothing/densifying — they
   faithfully follow the river course.
2. Residual ~2 parts/river of genuine NE discontinuities: ACCEPT the small gaps. Do
   NOT bridge them (bridging reintroduces teleport risk).

## Tests
- `testNoRiverPartHasLongStraightJump` (HanahuacTests/MapFeatureTests.swift, from #77)
  asserts no intra-part jump > 0.41° — it now encodes the WRONG invariant and will
  fail. REPLACE it with meaningful coverage for the new design:
  - no FALSE cross-piece joins (the real teleport guard ≈ JOIN_TOLERANCE bound)
  - bound parts-per-river to a sane maximum
  - assert the Lena is continuous (1 or very few parts)
- Keep passing the other river tests: 32/32 coverage, pin-on-path, Amazon stem,
  ≥3-vertex parts, Nile detailed centerline.

## Verification (VISUAL — mandatory)
#77 shipped a visible bug because verification was data-only. Render the regenerated
`river-paths.json` parts as separate matplotlib polylines and confirm:
- Lena and other Siberian rivers are CONTINUOUS
- NO long straight teleport lines reappear anywhere
- the within-segment reaches (esp. Lena's ~1.36°) look like faithful river course,
  not a cross-map teleport
Then `just install` so the user's /Applications app is current.

## Constraints
- All edits must pass `just lint` (ruff check + ruff format for the Python generator)
  and `just test`.
- NE downloads can hit `CERTIFICATE_VERIFY_FAILED`; use the documented `curl -sSL`
  cache workaround if refetching the rivers layer.
- Reuse worktree `ProjectHana-river-line-interruptions`, branch
  `feat/river-line-interruptions`. No new worktree/branch. Do not auto-merge.

## Out of scope
- Smoothing/densifying river geometry; bridging genuine NE gaps; touching
  `JOIN_TOLERANCE`; any change to unrelated rivers/categories.
