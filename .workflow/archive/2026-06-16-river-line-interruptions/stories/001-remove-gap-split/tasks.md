# Tasks — 001-remove-gap-split

- [x] Remove `gap_split()`, its call in `build_rivers()`, the `GAP_SPLIT_DEG` constant,
      the now-unused `itertools` import, and the gap-split references in the docstring.
      `JOIN_TOLERANCE` kept unchanged.
- [x] Run the generator in verify mode (32/32 + parts drop 2.53→2.03, Lena 10→1), then
      `--write` to regenerate `Hanahuac/Resources/river-paths.json`. Used curl/cert NE
      workaround (cache was missing).
- [x] Replace `testNoRiverPartHasLongStraightJump` with `testNoRiverPartHasCrossMapTeleportJump`,
      `testRiverPartCountStaysBounded`, `testLenaIsContinuous`.
- [x] `just lint` + `just test` clean; committed (bd1b304).
