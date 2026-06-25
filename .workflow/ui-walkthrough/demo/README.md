# Demonstrated end-to-end walkthrough — evidence (`demo` run)

This directory is the committed, verifiable artifact trail proving the UI-walkthrough driver
genuinely navigates **across multiple real screens**, not just code that could. It was produced by:

```sh
HANA_FEATURE_SLUG=agent-ui-driver \
  just ui-walkthrough .workflow/ui-walkthrough/scripts/full-walkthrough.json demo
```

The driver always emits step `000` (the post-launch initial state), then a `NNN-step.png` screenshot
**and** a `NNN-step.json` accessibility-element dump after **every** action in
[`../scripts/full-walkthrough.json`](../scripts/full-walkthrough.json).

> The simulator was running in **Spanish** for this capture, so on-screen text is localized
> (e.g. "Opción Múltiple" = Multiple Choice, "Aprender" = Learn, "Salir" = Exit, "Ajustes" =
> Settings). Targeting uses language-independent accessibility **identifiers** for navigation; the
> one label-targeted tap uses the live "Salir" (Exit) label.

## Demonstrated path

**Home → open the Multiple Choice quiz → answer a question → return Home → open Settings.**

## Step index

| Step | Action (from script)                         | Screen reached / what it shows                                   |
| ---- | -------------------------------------------- | --------------------------------------------------------------- |
| 000  | (initial launch — always captured)           | **Home** — mode list (Map Tap / Multiple Choice / …).           |
| 001  | `dumpTree`                                   | **Home** — explicit element-dump marker.                        |
| 002  | `screenshot`                                 | **Home** — explicit screenshot marker.                          |
| 003  | `tap` identifier `home.mode.multipleChoice`  | **Multiple Choice quiz** — "What is the capital of Ukraine?".   |
| 004  | `wait` 2s                                    | Quiz — settle after navigation.                                 |
| 005  | `dumpTree`                                   | Quiz — element dump showing `quiz.answer.*` options.            |
| 006  | `tap` identifier `quiz.answer.0`             | Quiz — answer registered (correct option "Kyiv" turns green).   |
| 007  | `wait` 1s                                    | Quiz — settle after the answer feedback.                        |
| 008  | `typeText` identifier `quiz.input` "Nairobi" | Quiz — no text field here, so gracefully skipped (action exercised). |
| 009  | `mapTap` x=0.5 y=0.45                         | Quiz — taps a normalized coordinate (mapTap action exercised).  |
| 010  | `scroll` direction `down`                    | Quiz — scroll/swipe gesture on the quiz view.                   |
| 011  | `wait` 1s                                    | Quiz — settle.                                                  |
| 012  | `tap` label `Salir` (Exit)                   | **Home** — label-targeted tap dismisses the quiz back to Home.  |
| 013  | `wait` 2s                                    | **Settings** — opens after the settings tap registers.          |
| 014  | `wait` 2s                                    | **Settings** — "Ajustes": General / Idioma + iCloud sync.       |
| 015  | `screenshot`                                 | **Settings** — explicit final screenshot marker.                |
| 016  | (final artifact for step 015)                | **Settings**.                                                   |

> Step 013 is the artifact captured immediately after the `tap` identifier `home.settings` step;
> the Settings screen is fully visible by step 014/015.

## Supported actions exercised (collectively, across the run)

| Action               | Step(s)        |
| -------------------- | -------------- |
| `tap` by identifier  | 003, 006, 013  |
| `tap` by label       | 012 ("Salir")  |
| `typeText`           | 008            |
| `mapTap` (normalized)| 009            |
| `swipe` / `scroll`   | 010            |
| `wait`               | 004, 007, 011, 013, 014 |
| `dumpTree`           | 001, 005       |
| `screenshot`         | 002, 015       |

## Key distinct screens (open the PNGs to verify)

- `000-step.png`, `002-step.png`, `012-step.png` — **Home**.
- `003-step.png`, `006-step.png` — **Multiple Choice quiz** (006 shows the answer feedback).
- `013-step.png`, `015-step.png` — **Settings**.
