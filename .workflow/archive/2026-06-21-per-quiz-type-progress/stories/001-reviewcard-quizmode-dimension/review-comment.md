<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context 4-eye review of the additive `quizMode` data-model foundation.

**Verdict: APPROVED** — no blocking findings.

What was checked:
- **Additive/CloudKit-safe:** both new `quizMode` columns are defaulted `String = ""`, no
  `@Attribute(.unique)` — preserves sync readiness and lightweight-migratability. ✓
- **Schema bump consistency:** `SchemaV2` → `SchemaV3` (3.0.0) is applied uniformly across
  `HanahuacSchema` (single version, no stages — correct for a purely additive default),
  `HanahuacMigrationPlan`, and `SyncCoordinator.makeModelContainer()`; no stray `SchemaV2` reference
  remains. ✓
- **No call-site breakage:** the new `quizMode:` init params are defaulted, so every existing
  `ReviewCard(...)` / `DailyProgressSnapshot(...)` call site keeps compiling. ✓
- **Token bridge:** `HomeQuizMode.quizModeID` / `init(quizModeID:)` are exhaustive 4-case switches and
  round-trip-tested; `QuizModeID` is correctly Foundation-only so the model/store/migrator layers can
  share the constant set without a SwiftUI dependency. ✓
- **No behavior change yet:** stores still operate with `quizMode == ""` until Story 002/005, so
  `CardStore`/`ProgressStatsStore` dedup grouping is unaffected by this commit. Per-mode scoping is
  correctly deferred to later stories. ✓
- **Tests:** new `QuizModeDimensionTests` pins defaults, cross-mode coexistence of the same
  `(factID, language)`, token round-trip, and the migration target; CI Build & Test + Lint green.

Note: `quizModeRawValue` is currently unused — intentional forward-provisioning for Stories 002–005;
not a finding.

Ready to merge.
