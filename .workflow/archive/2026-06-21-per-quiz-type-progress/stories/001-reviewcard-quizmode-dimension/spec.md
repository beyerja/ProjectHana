# Story 001 — Add a quiz-mode dimension to the persisted progress models

## Goal
Give the spaced-repetition data model a second, orthogonal `quizMode` dimension alongside the existing
`language` dimension, so a fact's progress can be tracked independently per quiz mode. This story is
the data-model foundation: it only adds the column(s), a stable mode identifier, and the schema bump.
It must not change any runtime behavior yet (every store still defaults `quizMode` to the legacy
sentinel), so the build and all existing tests stay green on this commit alone.

## Background
`ReviewCard` and `DailyProgressSnapshot` are SwiftData `@Model`s already carrying a defaulted
`language: String = ""`. Card identity today is `(factID, language)`. `HomeQuizMode` enumerates the
modes (`mapQuiz`, `multipleChoice`, `typeCapital`, `nameFeature`) but is a SwiftUI/`Hashable` enum with
associated UI; it is not a stable persisted token. The head schema is `SchemaV2`.

## Scope
- Add a defaulted `var quizMode: String = ""` stored column to `ReviewCard` (and to its `init`,
  CloudKit-safe: defaulted, never `@Attribute(.unique)`). Card identity becomes
  `(factID, language, quizMode)`. Empty string is the legacy/unassigned sentinel.
- Add a defaulted `var quizMode: String = ""` column to `DailyProgressSnapshot` likewise (its identity
  becomes `(day, language, quizMode)`; the aggregated/default snapshot keeps `quizMode == ""`). Wiring
  of per-mode snapshot recording is Story 003 — here only the column is added.
- Introduce a stable persisted token for a quiz mode. Add a `rawValue`-style identifier that maps each
  `HomeQuizMode` case to a stable string (`"mapQuiz"`, `"multipleChoice"`, `"typeCapital"`,
  `"nameFeature"`) — e.g. a `HomeQuizMode.quizModeID: String` computed property (and a reverse
  initializer) — so stores and the migrator key on these constants rather than the legacy sentinel or
  ad-hoc literals. `mapQuiz` is the migration target constant used by Story 005.
- Bump the head schema to `SchemaV3` (additive, model-level-defaulted → SwiftData lightweight
  migration, identical pattern to the V1→V2 add). Update `HanahuacMigrationPlan.schemas` and
  `SyncCoordinator.makeModelContainer()` to open against `SchemaV3`. Preserve the doc rationale about
  why a purely-additive default is a single-version plan with no explicit stages.

## Acceptance Criteria
- [ ] `ReviewCard` has a defaulted `quizMode: String = ""` stored property, wired through its `init`;
      no `@Attribute(.unique)` anywhere.
- [ ] `DailyProgressSnapshot` has a defaulted `quizMode: String = ""` stored property wired through
      its `init`.
- [ ] A stable mode-token API exists mapping every `HomeQuizMode` case to/from a constant string; the
      `mapQuiz` constant is exposed for the migrator.
- [ ] Head schema is `SchemaV3` (`Schema.Version(3, 0, 0)`); `HanahuacMigrationPlan` and
      `SyncCoordinator.makeModelContainer()` reference it; the additive change remains a SwiftData
      lightweight migration (existing rows preserved, `quizMode` defaults to "").
- [ ] No call site is forced to pass `quizMode` yet (default keeps every existing store/seed path
      compiling and behaving exactly as before).
- [ ] `just build` and `just test` are green; existing per-language tests still pass unchanged.
