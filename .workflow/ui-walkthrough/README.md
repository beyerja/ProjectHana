# UI walkthrough driver

A data-driven XCUITest "driver" that launches the Hanahuac app, executes a JSON action script step by
step, and records a screenshot + accessibility-element dump after **every** step. It lets the main
session and workflow sub-agents (`verify-story`, `verify-feature`) exercise real UI flows without
hand-writing `xcodebuild` invocations.

## The write-script → run → read-artifacts loop

1. **Write** an action script (JSON) under `.workflow/ui-walkthrough/scripts/<name>.json`.
2. **Run** it against the booted simulator:

   ```sh
   just ui-walkthrough .workflow/ui-walkthrough/scripts/<name>.json
   # or, with the committed smoke example as the default:
   just ui-walkthrough
   # pin an explicit run-dir name (otherwise a UTC timestamp is used):
   just ui-walkthrough .workflow/ui-walkthrough/scripts/<name>.json my-run
   ```

3. **Read** the artifacts the recipe prints the path to (see *Where artifacts land*).

> **Performance reality.** Each run is a full **compiled `xcodebuild test` cycle — on the order of
> tens of seconds**, NOT a live, frame-by-frame interactive session. You author a complete script,
> run it once, and inspect the emitted artifacts; you do not steer the app in real time.

## Action-script JSON schema

A script is a **JSON array** of step objects. Each step has a required `action` and a set of optional
fields; the driver reads only the fields relevant to the step's action. An empty, missing, or
malformed script is **not** an error — the app still launches and emits the initial `000` artifacts.

```json
[
  { "action": "wait", "seconds": 1 },
  { "action": "dumpTree" }
]
```

### Fields

| Field        | Type                              | Used by                | Meaning                                                        |
| ------------ | --------------------------------- | ---------------------- | ------------------------------------------------------------- |
| `action`     | string (required)                 | all                    | Which action to perform (see table below).                    |
| `label`      | string                            | `tap`, `typeText`, `swipe`/`scroll` | Accessibility **label** of the target (preferred matcher). |
| `identifier` | string                            | `tap`, `typeText`, `swipe`/`scroll` | Accessibility **identifier** of the target (fallback).     |
| `text`       | string                            | `typeText`             | Text to type into the resolved (or first) text field.        |
| `x`, `y`     | number, normalized `0.0`–`1.0`    | `mapTap`               | Normalized tap coordinate within the app frame.              |
| `direction`  | `up` \| `down` \| `left` \| `right` | `swipe`, `scroll`    | Direction to swipe/scroll (defaults to `up`).                |
| `seconds`    | number                            | `wait`                 | How long to sleep.                                            |
| `scale`      | number (**required** for `pinch`) | `pinch`                | Pinch scale factor: `< 1` zooms **out**, `> 1` zooms **in**. |
| `velocity`   | number                            | `pinch`                | Pinch velocity (optional). Default is **scale-aware**: negative for zoom out (`scale < 1`), positive for zoom in (`scale > 1`). |

> **Targeting order:** the driver resolves a target by accessibility **label first**, then falls back
> to **identifier**. Unresolvable targets are skipped (not failed) so artifact collection continues.

### Supported actions

| Action       | Effect                                                                              |
| ------------ | ---------------------------------------------------------------------------------- |
| `tap`        | Tap the element resolved by `label`/`identifier`.                                  |
| `typeText`   | Tap the resolved element (or first text field) and type `text`.                    |
| `mapTap`     | Tap a normalized `x`/`y` coordinate (for the map, which has no addressable element).|
| `swipe`      | Swipe the resolved element (or whole app) in `direction`.                          |
| `scroll`     | Alias of `swipe` (same direction handling).                                        |
| `pinch`      | Pinch the resolved element (or whole app) by `scale` (`<1` zoom out, `>1` zoom in).|
| `wait`       | Sleep for `seconds`.                                                               |
| `dumpTree`   | No extra action — realized by the element dump emitted after every step.           |
| `screenshot` | No extra action — realized by the screenshot emitted after every step.             |

Because a screenshot **and** element dump are written after *every* step, `dumpTree`/`screenshot`
exist as explicit, self-documenting no-op markers in a script.

> **`pinch` (zoom):** `scale` is **required** — `< 1` zooms **out**, `> 1` zooms **in**. `velocity`
> is optional; when omitted its default is **scale-aware** — negative for zoom out (`scale < 1`) and
> positive for zoom in (`scale > 1`), as `XCUIElement.pinch(withScale:velocity:)` requires the
> velocity sign to match the scale (a mismatched pair raises `NSInvalidArgumentException`). An
> explicitly supplied `velocity` is used as-is. The driver pinches the element resolved by `label`/`identifier`,
> falling back to the whole app when no target is given (so it works on the map, which has no
> addressable element). A `pinch` with no `scale`, or whose targeted element never appears, is
> **skipped** (no crash, no failure) and per-step artifacts are still captured. Example — zoom the
> map out:
>
> ```json
> [
>   { "action": "pinch", "scale": 0.5 }
> ]
> ```

## Environment-variable contract

The recipe + helper (`scripts/ui-walkthrough.sh`) plumb these through to the driver; you normally do
not set them by hand:

| Variable              | Purpose                                                                          |
| --------------------- | ------------------------------------------------------------------------------- |
| `HANA_UI_SCRIPT_PATH` | Filesystem path to the JSON action script. **Preferred** input.                 |
| `HANA_UI_SCRIPT`      | Inline JSON action script. Used only when `HANA_UI_SCRIPT_PATH` is unset/blank. |
| `HANA_REPO_ROOT`      | Absolute repo checkout path so artifacts land in this real `.workflow/` tree.    |
| `HANA_UI_RUN`         | Overrides the `<run>` directory name (otherwise a UTC timestamp is used).        |

> **Why the helper sets `TEST_RUNNER_*`:** `xcodebuild` does **not** forward the launching shell's
> environment into the sandboxed XCUITest runner. Only variables prefixed `TEST_RUNNER_` are injected
> into the runner (the prefix is stripped before the driver reads them). So `scripts/ui-walkthrough.sh`
> exports `TEST_RUNNER_HANA_REPO_ROOT` / `TEST_RUNNER_HANA_UI_SCRIPT_PATH` / `TEST_RUNNER_HANA_UI_RUN`,
> and the driver sees the bare `HANA_*` names. Without the prefix the recorder falls back to the app's
> sandbox tmp dir and nothing lands in the repo tree.

## Canonical locations

- **Action scripts** (committed, tracked): `.workflow/ui-walkthrough/scripts/<name>.json`
  — e.g. the example `smoke.json` (`wait` + `dumpTree`).
- **Run artifacts** (per run, git-ignored): `.workflow/ui-walkthrough/<run>/`
  - `NNN-step.png`  — full-screen screenshot for step `NNN` (3-digit, zero-padded).
  - `NNN-step.json` — recursive accessibility-element dump (type / label / identifier / value / frame).

Step `000` is always the initial state captured immediately after launch, before any script step runs.

## Where artifacts land

Under `<HANA_REPO_ROOT>/.workflow/ui-walkthrough/<run>/`. The run directory is the `HANA_UI_RUN` name
when set, otherwise a UTC `yyyyMMdd-HHmmss` timestamp. The `just ui-walkthrough` recipe prints the
resolved artifact directory on success.

> Run-output directories are **git-ignored** (see the repo `.gitignore`); only the `scripts/` action
> scripts and this `README.md` are tracked. Do not commit run output.
