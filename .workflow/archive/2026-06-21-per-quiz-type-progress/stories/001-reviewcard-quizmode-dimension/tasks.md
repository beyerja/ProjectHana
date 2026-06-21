## Tasks
- [x] 001: Add a stable `quizModeID` token API (Foundation-only `QuizModeID` enum in Models; `HomeQuizMode.quizModeID`/`init(quizModeID:)` bridge in QuizRoute.swift); `mapQuiz` exposed via `QuizModeID.legacyMigrationTarget`.
- [x] 002: Added defaulted `var quizMode: String = ""` to `ReviewCard` + init; identity doc updated.
- [x] 003: Added defaulted `var quizMode: String = ""` to `DailyProgressSnapshot` + init; aggregate/legacy doc.
- [x] 004: Audited tests constructing the models — defaulted column keeps memberwise inits compiling; no existing test asserts on changed identity/defaults. All green.
- [x] 005: Bumped head schema to `SchemaV3` (3.0.0), updated `HanahuacMigrationPlan` + `SyncCoordinator.makeModelContainer()` + doc rationale.
- [x] 006: `just generate` (2 files added), `just lint` clean, `just test` SUCCEEDED. Added `QuizModeDimensionTests` (defaults, cross-mode coexistence, token round-trip, migration target).
