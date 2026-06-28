---
name: implement-story
description: Implement all pending tasks for a story on a feature branch, running project checks after each commit
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
just log start implement-story "<story-id>" || true
```
(derive `<story-id>` from the last path component of the story dir, e.g. `001-telemetry-infrastructure`)

Read `<story-dir>/tasks.md`.

**Branch name (feature-slug namespaced)** — so parallel feature workflows in separate worktrees never
collide. The orchestrator exports `HANA_FEATURE_SLUG` (the shared feature slug, also used for the
worktree, build isolation, and telemetry tagging). Compute the branch once:
```sh
slug="${HANA_FEATURE_SLUG:-}"
branch="story/${slug:+$slug/}<story-id>"   # → story/<slug>/<story-id> when set, else story/<story-id>
```
Ensure you are on `$branch` (create it from the worktree's base branch if needed). Never hardcode a
flat `story/<story-id>` — always go through `HANA_FEATURE_SLUG` so single-checkout runs keep the
legacy name while worktree runs are namespaced.

**For a bug-fix story, confirm the root cause in code before changing anything.** When the story is a
fix (not a new feature), the leading hypothesis in the spec is a *hypothesis*, not a verified cause —
trace the actual code path and prove the mechanism before editing. State in the story log what you
confirmed AND which competing theories you ruled out (e.g. for a mis-centering bug: confirm the camera
path, then rule out the region math, a lat/lon swap, and a data error). Fixing the first plausible
theory without this often patches a symptom and leaves the real defect; the cheap confirmation pass up
front is what makes the fix land at the right altitude in one shared code path.

For each unchecked task:
1. Implement following existing project patterns
2. Run project checks. **In a worktree run, invoke `just` at the worktree path** —
   `just -f <worktree>/justfile lint` / `… test` (the recipes are worktree-aware) — never
   `cd <worktree> && just …`. That `cd <worktree> && …` compound is the single most-prompted command
   in telemetry and stayed the top offender even after the rule landed in CLAUDE.md, so emit the
   at-a-path shape here (see CLAUDE.md → "Emit allowlistable command shapes"):
   ```sh
   just lint   # fail-on-violation lint gate (Swift/Python/Shell/Nix/YAML); blocks the PR in CI
   just test
   ```
3. Fix any failures and retry until clean
4. Commit with a clear message. For a multi-line body, write the message to a file with the Write tool
   and `git commit -F <file>` (or `git -C <worktree> commit -F <file>`) — never `git commit -m "$(cat
   <<'EOF')"` or `commit -F - <<'EOF'` (heredocs/`$(…)` are always prompted; see CLAUDE.md → "Emit
   allowlistable command shapes"). Run git at a path (`git -C <worktree>`), never `cd … && git …`.
5. Mark task checked in `tasks.md`

**Write Swift that passes the lint gate the first time.** The strict SwiftLint + `swiftformat --lint`
gate fails the build on these recurring violations — get them right while writing, not on a retry:
- No trailing comma after the last element of a collection literal (`trailing_comma`).
- Use `min()`/`max()` / `min(by:)`/`max(by:)`, never `sorted().first`/`.last` (`sorted_first_last`).
- No `x.map { … } ?? nil` — use `flatMap` (`redundant_nil_coalescing`).
- Keep every line ≤120 chars (`line_length`) — break long `XCTAssert…(…, file:, line:)` calls and
  long expressions across lines, or hoist sub-expressions to locals, while writing.
- Tuples may have at most 2 members (`large_tuple`) — for a 3+ field return value (e.g. a
  min/max lat/lon rect) declare a small named `struct`, never a 4-tuple.
- Wrap single-line property bodies and loop bodies onto their own lines, in **production code too**,
  not just tests (`wrapPropertyBodies`, `wrapLoopBodies`) — e.g. write
  `var x: [T] {\n    expr\n}`, never `var x: [T] { expr }`.
- In **tests**: never force-unwrap (`!`) — use `try XCTUnwrap(...)` and make the method `throws`;
  hoist `try` to the start of the expression, not inline (`hoistTry`); drop `throws` if nothing throws
  (`redundantThrows`).

**SwiftData schema changes**
When adding or removing fields on an `@Model` type:
- The store opens through a **versioned schema + migration plan** (`Hanahuac/Sync/HanahuacSchema.swift`:
  `SchemaV2` / `HanahuacMigrationPlan`). For a purely **additive** change (a new stored property that
  carries a model-level default), DO NOT add a second `VersionedSchema` joined by
  `.lightweight(fromVersion:toVersion:)`: a plan listing two versions that both point at the *same live
  `@Model` types* aborts at container creation on a clean store with "retrieve an NSManagedObjectModel
  version checksum while the model is still editable" (a stale local store masks it — it only shows up in
  CI / after `simctl erase`). Instead bump the single head `SchemaVN` to the new shape and list ONLY it
  (no stages); SwiftData performs the additive lightweight migration automatically and the existing
  on-disk store upgrades **in place** (progress preserved). A real multi-version `.lightweight`/custom
  stage is only correct between *distinct frozen* schema types (a NON-additive change). Either way, do
  NOT rely on the recovery path to discard data: `SyncCoordinator.makeModelContainer()` is intentionally
  **non-destructive** — it backs the store up before any wipe and only wipes as a last resort.
- Non-optional fields without a default value still crash on launch against a store that predates a
  proper migration. When iterating in the simulator, wipe the simulator's store (`xcrun simctl uninstall
  booted <bundle-id>`) so a stale local store doesn't mask a missing migration stage.
- After any schema change, grep all existing tests that construct the changed model type and verify they pass the new required fields. Tests that create model instances and omit new non-optional properties will produce compiler errors; tests that rely on old default values (e.g. `hasGraduated: false`) may silently produce wrong results — audit those explicitly.
- In tests, use `ModelConfiguration(isStoredInMemoryOnly: true)` so they never touch the on-disk store.

**Adding a field to a plain `Codable` struct breaks its memberwise-init call sites**
Adding a stored property to a `Codable struct` (e.g. the `Country`/`River`/`Sea`/`MountainRange` geo
models) gives Swift's *synthesized* memberwise init a new required parameter, so every `Type(...)`
call site — often spread across many test files — stops compiling at once. Instead of editing every
call site, add an **explicit memberwise `init` that defaults the new field(s)** (e.g.
`nameKo: String? = nil`); `Codable` still decodes the new key via `decodeIfPresent`. Faster and
lower-risk than touching dozens of call sites.

**Adding an `AppLocale` case touches a fixed fan-out — update the whole set in one commit**
A new locale is not done when `Country` compiles. It requires, every time: a `nameXx` (and
`capitalXx` where present) on **all four** geo models — `Country`, `River`, `MountainRange`, `Sea`
(not just `Country`) — and a new `case .xx` arm in **every** exhaustive switch over `AppLocale`,
including the five in `GeoModel+PackData.swift`. Before committing, grep the full site set
(`grep -rn "case .esES\|nameXx" Hanahuac/`) and confirm each model and each switch is updated; a
partial set is a "switch must be exhaustive" build failure. Keep this fan-out within a single commit
so an interrupted WIP still compiles rather than leaving three models and the switches behind.

**Tests must not assert on ambient bundle/resource presence — drive through the seam**
A test that asserts a resource is present in (or absent from) `Bundle.main` is environment-dependent and
will pass locally but fail in clean CI. The Catalyst/sim dev build embeds tagged ODR resources in the
test host, but a clean CI/App-Store build splits them into on-demand asset packs, so `Bundle.main`
contents differ. Any test about pack presence/absence or offline-fallback behavior must resolve through
the provider seam with an **explicit test double** (e.g. a local `PackAbsentProvider` that returns the
intended state), restoring the active provider in `setUp`/`tearDown` — never rely on what happens to be
embedded in `Bundle.main` at runtime.

**Never degrade a completeness/enforcement test to pass — fix the wiring instead**
When a story flips a language/feature to a "fully enforced" state, its strict completeness test (e.g.
`test<Lang>HasFullGeoCoverage`, a no-fallback guarantee) is the *whole point* — it must FAIL until the
real wiring is done. If that test fails because a switch arm still returns `nil` or a provider list
omits the new entry, the fix is to **complete the wiring**, never to wrap the assertion in `XCTSkip`,
`try?`, or a `do/catch` that swallows the failure. A skip/catch on the enforcement assertion silently
disables the guarantee the story exists to add — it is a degrade-to-pass and a blocking defect.
(The legitimately-skippable case is narrow and separate: a test that reads an **ambient bundle
resource not mounted in the sim/test host** may `XCTSkip` on unreachability — see the bundle-seam rule
above — but the *enforcement* assertion itself, driven through the provider seam or checked-in source,
must always run with real teeth.)

**Xcode project is generated — never hand-edit the pbxproj**
The project is generated from `project.yml` by xcodegen. Source/resource files are enumerated
from folder paths (`Hanahuac/`, `HanahuacTests/`), so after **adding or removing any file** run:
```sh
just generate
```
Then `just test`. Do NOT manually edit `Hanahuac.xcodeproj/project.pbxproj` — it is overwritten by
`just generate`. To change targets, settings, schemes, or the bundle id, edit `project.yml` and
regenerate. (Files inside `*.xcassets` — e.g. app-icon PNGs — are folder-referenced and need no
regeneration.)

When you add several **parallel** entries to `project.yml` (e.g. one per locale: `fr.lproj`, `de.lproj`,
`ko.lproj`, …), make them **structurally identical** — same keys (`type: folder`, `resourceTags`, etc.).
One entry missing a key (e.g. a `.lproj` without `type: folder`) silently generates a different pbxproj
path (a `<group>` instead of a folder ref), changing ODR delivery/resolution on a real split build. After
regenerating, diff the generated entries to confirm the parallel set matches.

**Git hooks must install under the repo's actual `core.hooksPath` — and be tested there**
This repo sets `core.hooksPath=.githooks`, so git runs `.githooks/<hook>`, NOT `$GIT_DIR/hooks/<hook>`.
A hook written into `$GIT_DIR/hooks/` is **silently inert** — it never fires (a real miss this workflow
cost 3 review rounds). When adding hook behavior: compose it into the committed `.githooks/<hook>` (and
have the installer set `core.hooksPath` idempotently), never drop a shim into `$GIT_DIR/hooks/`. Then
make at least one regression test stand up a throwaway repo wired **exactly** like this one
(`core.hooksPath=.githooks`, the `.githooks/` dir + scan script copied in) and drive a **real**
`git commit` to prove the hook executes — a test that commits in a default repo without `core.hooksPath`
passes while the shipped hook is dead.

**A full-object PUT replaces the whole resource — enumerate fields you must preserve**
When committing a config payload applied via a replace-semantics call (notably
`gh api -X PUT repos/.../branches/.../protection` with `--input <branch-protection>.json`), the PUT
**replaces the entire object** — any field set to `null` or omitted WIPES that setting. A
`required_status_checks: null` in the body would delete main's existing required CI checks (gitleaks,
Build & Test) on activation. Before committing such a payload, GET the live resource read-only and
enumerate every field that must survive (e.g. `{strict:true, contexts:[<live checks>]}`), and note in
the accompanying doc that the PUT replaces the whole object.

**Builds and tests go through `just` — no manual env**
Use `just build-sim`, `just test`, `just build-mac`, `just generate`, `just icon`. These carry the
correct toolchain via flake + direnv. Never prefix commands with `DEVELOPER_DIR=…`, `ZDOTDIR=…`, or
`export PATH=/nix/…` — the environment is already wired (see `.envrc`, `flake.nix` `mkShellNoCC`,
and `.claude/shell/.zshenv`).

**Avoid redeclaration before adding extensions**
Before adding a new `extension` on any existing type (model, enum, struct), grep the codebase for existing extensions and computed properties on that type:
```sh
grep -r "extension <TypeName>" Hanahuac/
```
If a property or method you are about to add already exists in another file, reuse it — do not redeclare it. Common culprits: `displayName`, `localizedName`, `color`, `iconName` on model types used in multiple views.

**Overloaded methods that take different enums with shared case names are ambiguous at leading-dot call sites**
When a new orthogonal dimension adds a second enum (e.g. a persisted `QuizModeID` alongside the
SwiftUI `HomeQuizMode`, both with cases `mapQuiz`/`multipleChoice`/…), do NOT give one type two
`func foo(for:)` overloads — one per enum. A call like `provider.foo(for: .multipleChoice)` then fails
to compile with `ambiguous use of '.multipleChoice'` because the leading-dot literal matches both
overloads. Give the overloads **distinct labels** (`store(for: HomeQuizMode)` vs
`store(forModeID: QuizModeID)`) so call sites resolve unambiguously without forcing every caller to
spell out `HomeQuizMode.multipleChoice`.

**iOS-only APIs**
Modifiers unavailable on macOS (`navigationBarTitleDisplayMode`, `textInputAutocapitalization`, etc.) must use the wrappers in `Hanahuac/Views/ViewExtensions.swift` rather than direct calls.

**XCUITest/UITest APIs can be platform-conditional — `just test` locally does NOT cover the CI target set**
Local `just test`/`just ui-walkthrough` build the **iOS Simulator** test target; CI also builds the
**Mac Catalyst** test target. Some XCUITest APIs exist on one and not the other — e.g.
`XCUIElement.pinch(withScale:velocity:)` compiles for the Simulator but is **unavailable on Mac
Catalyst**, so a green local run still breaks the CI build (a real detour this workflow). When adding a
UITest gesture/API, guard the platform-specific call behind `#if targetEnvironment(macCatalyst)` with a
non-no-op fallback (synthesize the gesture from `XCUICoordinate` press-drag so the contract still holds),
and route both call sites through one helper. Confirm with a Catalyst `xcodebuild build-for-testing`
before pushing — the simulator pass alone will not catch it.

**Bundled Natural-Earth geo data (generate-*.py pattern)**
When a story derives bundled geo data from Natural Earth (rivers, borders, etc.):
- The framework Python may fail the NE download with `CERTIFICATE_VERIFY_FAILED`. Download the layer zip with `curl -sSL` into the script's cache dir (`$TMPDIR/ne-borders-cache`) and unzip it there; the script then finds the cached `.shp` and skips its own download.
- Probe the NE shapefile (names, `name_en`, `name_alt`, `rivernum`) to confirm each curated match BEFORE finalizing the id→NE map — NE per-segment names vary and differ from display names. Match by the stable `rivernum` when the name is ambiguous or absent (e.g. Yellow River is NE name "Huang"/rivernum 66+95, not "Huang He"). Do the probing in one script, not many one-off `python3 -c` calls.

After all tasks are done:
6. Run `just install` **only if** the story adds new Swift files or introduces UI modifiers / APIs not already present in the codebase. Skip it for changes that only modify existing logic, geometry, or data within SwiftUI view bodies using patterns already in the project — and note the skip in the telemetry notes. When in doubt, run it.

**Telemetry — run before appending to log.md:**
Count your tool calls in this run: R = Read calls, W = Write calls, E = Edit calls, B = Bash calls. Estimate total chars processed (sum of file sizes read + written). Then run (ignore errors):
```
just log end implement-story "<story-id>" <R> <W> <E> <B> <est_chars> "<retries and notable issues>" || true
```
The `notes` argument is passed through the shell unquoted by `just`; `;`, `&`, `|`, and `()`
inside it break the call. Keep notes to plain hyphen/space tokens (e.g. `"1-retry-schema-wipe"`).

Append to `<story-dir>/log.md`: `<timestamp> implement-story: DONE — <tasks completed>, <issues if any>`.

Output STATUS: DONE.
