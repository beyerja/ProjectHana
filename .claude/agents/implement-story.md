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
4. Commit with a clear message
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
- In **tests**: never force-unwrap (`!`) — use `try XCTUnwrap(...)` and make the method `throws`;
  hoist `try` to the start of the expression, not inline (`hoistTry`); drop `throws` if nothing throws
  (`redundantThrows`); wrap loop bodies and single-line property bodies onto their own lines
  (`wrapLoopBodies`, `wrapPropertyBodies`).

**SwiftData schema changes**
When adding or removing fields on an `@Model` type:
- Non-optional fields without a default value will crash on launch if the simulator's store is stale. Before running tests, wipe the store: in the simulator, long-press the app icon → Remove App (or `xcrun simctl uninstall booted <bundle-id>`). The app's `ModelContainer` catch block should already handle this in development, but the simulator must be clean.
- After any schema change, grep all existing tests that construct the changed model type and verify they pass the new required fields. Tests that create model instances and omit new non-optional properties will produce compiler errors; tests that rely on old default values (e.g. `hasGraduated: false`) may silently produce wrong results — audit those explicitly.
- If the story spec does not include a migration plan, use `ModelConfiguration(isStoredInMemoryOnly: true)` in tests so they never touch the on-disk store.

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
