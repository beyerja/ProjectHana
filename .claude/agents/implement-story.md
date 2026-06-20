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

For each unchecked task:
1. Implement following existing project patterns
2. Run project checks:
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

**iOS-only APIs**
Modifiers unavailable on macOS (`navigationBarTitleDisplayMode`, `textInputAutocapitalization`, etc.) must use the wrappers in `Hanahuac/Views/ViewExtensions.swift` rather than direct calls.

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
