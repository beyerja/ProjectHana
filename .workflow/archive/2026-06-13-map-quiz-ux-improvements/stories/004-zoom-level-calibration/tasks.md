## Tasks

- [x] 001: Create a new file `ProjectHana/Views/Quiz/MapQuiz/MapQuizRegionHelper.swift` that contains a free function `makeQuizAnnotations(correct:allCountries:neighbourCount:)` returning `([Country], MKCoordinateRegion)`: picks the nearest `neighbourCount` countries globally (not just same continent), returns them shuffled, and computes a region with a random center offset so the target country can appear anywhere in the viewport
- [x] 002: Replace `refreshAnnotations` / `region(for:)` / `distance(_:from:)` in `MapQuizSession` to use the shared helper (pass `neighbourCount: 10`)
- [x] 003: Replace the equivalent private methods in `MapLearningSession` to use the same helper (pass `neighbourCount: 10`)
- [x] 004: Add the new file to `ProjectHana.xcodeproj/project.pbxproj`
- [x] 005: Add unit tests in a new `MapQuizRegionHelperTests.swift`: verify at least 10 annotation countries returned, verify center offset applied (center != target coordinate), verify helper is used by both session types
- [x] 006: Add `MapQuizRegionHelperTests.swift` to `project.pbxproj` test target
- [x] 007: Run `just test` and fix any failures
