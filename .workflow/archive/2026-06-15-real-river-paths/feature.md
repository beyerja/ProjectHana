# Feature: Real river paths in the map quiz

## Goal
The map quiz currently draws each river as a single straight (densified great-circle)
line between only two stored endpoints (source → mouth). This looks nothing like a real
river. Replace the two-endpoint model with real, multi-point river centerline geometry
sourced reproducibly from Natural Earth (`ne_10m_rivers_lake_centerlines`), so each
river renders as a path that follows its actual course. Preserve the straight
source→mouth line as a graceful fallback for any river that cannot be matched (mirrors
the mountains pin-only fallback).

## Clarification answers (recommended defaults — confirmed proceed by user)
1. **Coverage / fallback** — Ship real paths for every river Natural Earth covers
   (target 31/32 per the user's name-coverage check); keep the straight source→mouth
   line as a documented fallback for any river that can't be matched. No single river is
   important enough to hand-author at this stage; if NE genuinely omits one (or only has
   a delta segment, e.g. Irrawaddy), it falls back to the straight line and is recorded
   in the spec/tests as a known fallback.
2. **Pin placement** — Move the tappable pin onto a vertex near the midpoint of the real
   matched path so it sits on the actual river. Fallback rivers keep the
   source/mouth midpoint pin.
3. **Path fidelity / size** — Round coordinates to ~3 decimal places (matching the
   established `generate-borders.py` convention) and bundle the result, accepting a
   modest asset-size increase. Optionally simplify very dense segments only if size is
   unreasonable; correctness of the visible course takes priority.

## Acceptance Criteria
- [ ] A committed, documented, non-destructive generation script (`scripts/generate-river-paths.py`,
      same pattern as `generate-borders.py`: `--write` to regenerate, verify-by-default,
      pure-Python `pyshp`, curated id→NE-name map) produces `Hanahuac/Resources/river-paths.json`.
- [ ] The curated map includes the special cases: `yellow` → **Huang He**; `dnieper`
      matched correctly (NE `name_en`/`name_alt`, NOT fuzzy-matched to Dniester);
      Irrawaddy captures the **main river** not just the delta. Amazon→Amazonas,
      Yenisei→Yenisey, Senegal→Sénégal handled.
- [ ] NE line segments sharing a river's name are gathered and **stitched into an
      ordered path** (source→mouth where determinable); genuinely braided/disjoint
      rivers may carry multiple polyline parts.
- [ ] `river-paths.json` is keyed by our river `id` → ordered multi-point path(s)
      (e.g. `{"id":"nile","path":[[lon,lat],...]}` or a list of parts), bundled like the
      other Resources JSON (added to `Hanahuac/Resources/`, project regenerated via
      `just generate` — pbxproj never hand-edited).
- [ ] `MappableFeature` exposes a real multi-point line path (replacing the two-point
      `lineEndpoints`); `River` returns its sourced path, falling back to the straight
      source→mouth line when no path data exists. Countries/seas/mountains return no path.
- [ ] The tappable river pin sits on a vertex near the matched path's midpoint
      (fallback rivers keep the source/mouth midpoint).
- [ ] `MapFeatureRendering` feeds the real path(s) to `MapPolyline`, handling multi-part
      paths, and keeps the existing answer-state stroke colours.
- [ ] **Visual:** in the running app's river map quiz, a representative river (e.g. Nile
      or Amazon) renders as a curved path that follows the river course, NOT a straight
      line.
- [ ] Tests (HanahuacTests/MapFeatureTests.swift etc.) cover: every river either has a
      matched path or a documented straight-line fallback; path coordinate counts are
      sane (>2 for matched rivers); the pin sits on the path for matched rivers; fallback
      behaviour is exercised.
- [ ] `just test` passes; the feature ships via a PR to main with green CI (user merges).

## Constraints
- Reproducible-data convention is mandatory: no throwaway scripts. Follow the
  `generate-borders.py` pattern (download NE, curated map, proximity disambiguation,
  rounded coords, non-destructive default). The committed JSON is the reviewed source of
  truth; the script documents/regenerates it.
- xcodegen project: after adding `river-paths.json`, run `just generate`; never hand-edit
  `Hanahuac.xcodeproj/project.pbxproj`.
- Builds/tests via `just` only (flake + direnv); no manual env/PATH.
- Before adding extensions/computed properties on `River`/`MappableFeature`, grep for
  existing declarations to avoid redeclaration.
- PR-based flow with CI; the user merges PRs — do not auto-merge.
- All bundled geo work mirrors the established mountains pin-only graceful-degradation
  pattern for the fallback.

## Out of Scope
- Adding new rivers beyond the existing 32.
- Changing the river quiz/learning logic, scoring, or card data.
- Hand-authoring bespoke geometry for rivers NE cannot match (those keep the straight-line
  fallback for now).
- Reworking country/sea/mountain rendering beyond the `lineEndpoints`→`linePath`
  protocol change needed to keep them compiling.
