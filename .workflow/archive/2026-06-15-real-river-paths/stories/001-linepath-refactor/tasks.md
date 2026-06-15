## Tasks
- [ ] 001: Add RiverPathLoader.swift (mirrors BorderLoader): loads river-paths.json into id → [[CLLocationCoordinate2D]]; returns [:] when resource absent. Run just generate.
- [ ] 002: Refactor MappableFeature protocol: replace lineEndpoints with linePath: [[CLLocationCoordinate2D]]?. Update Country/Sea/MountainRange to return nil.
- [ ] 003: River conformance: linePath returns RiverPathLoader.shared[id] if present, else a single straight [source, mouth] part. pinCoordinate unchanged (midpoint).
- [ ] 004: Update MapFeatureRendering.featureOverlays to draw each linePath part as a MapPolyline (densify the fallback straight part); keep answer-state stroke colours.
- [ ] 005: Update MapFeatureTests for lineEndpoints→linePath; add fallback test (no path data → single straight part = source/mouth). Run just test.
