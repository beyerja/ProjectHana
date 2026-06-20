# Feature: Per-language progress tracking

## Goal
Track learning progress separately for each language so the app doubles as a tool for
learning geography *in a new language*. Switching the active language presents an independent,
persistent progress track — letting a user (re)learn the same geography content in a different
language from a clean slate, without disturbing their progress in any other language.

## Background (current state)
Progress today is **global** — it has no language dimension:
- `ReviewCard` (SwiftData `@Model`) — spaced-repetition state keyed by `factID` only;
  `CardStore` keys by `factID`.
- `DailyProgressSnapshot` — daily stats rollup keyed by `day` only; `ProgressStatsStore` keys by `day`.
- `StreakTracker` — a single global streak.
- `ActiveSetStore` — the active learning set (global).
- `LanguageManager.current` — active `AppLocale`, persisted via `PreferenceStore` (CloudKit-syncable).
  6 locales: `en, fr, de, es-MX, ko, nah`.
- Progress is built to be CloudKit-sync-ready (no `@Attribute(.unique)`, optional/defaulted fields,
  app-level dedup).

## Scope (clarified — FINAL)
ALL progress becomes per-language. Each of the following gains a language dimension and is tracked,
stored, and synced independently per `AppLocale`:
1. **Spaced-repetition card state** — `ReviewCard` / `CardStore`.
2. **Daily stats snapshots** — `DailyProgressSnapshot` / `ProgressStatsStore`.
3. **Streak** — `StreakTracker` becomes one streak per language.
4. **Active set** — `ActiveSetStore` becomes per-language.

## Behavior requirements
- **Independent + persistent tracks.** Switching EN→KO shows Korean as a fresh start (0 progress);
  English is left untouched; switching back to English restores English's progress exactly.
- **Migration.** On upgrade, attribute ALL existing (global) progress to the **currently-active
  language** at upgrade time. Every other language starts empty. Migration runs once, is idempotent,
  and must not lose or duplicate existing progress.
- **Content model flexibility.** Same fact universe across languages *today*, but the data model must
  STAY FLEXIBLE to per-language fact divergence later (different/extra facts per language). Do NOT
  hardcode the assumption that every language shares an identical fact set. Progress keys on
  (`factID`, `language`); a `factID` absent in a given language simply has no progress there.
- **CloudKit sync.** Preserve per-language sync. Dedup is keyed by `factID` + `language`. No languages
  are excluded from sync. Keep the sync-ready constraints (no `.unique`, optional/defaulted fields).
- **Stats UI.** Default view shows the ACTIVE language's progress. Additionally provide an option to
  view a per-language breakdown / comparison across languages.

## Acceptance criteria
1. Card review state, daily snapshots, streak, and active set are each stored and queried per
   `AppLocale`; no cross-language bleed.
2. Switching language swaps the visible progress track and leaves all other tracks untouched;
   switching back restores the prior track exactly (verified by tests).
3. A one-time, idempotent migration attributes pre-existing global progress to the active language at
   upgrade; re-running it does not duplicate or drop data.
4. Dedup logic keys on (`factID`, `language`); two languages may hold a progress row for the same
   `factID` without collision.
5. The data model permits a `factID` to exist in one language but not another (no schema-level
   assumption of a shared fact set).
6. Stats UI defaults to the active language and offers a per-language breakdown/comparison view.
7. CloudKit-sync readiness is preserved (no `@Attribute(.unique)`, optional/defaulted fields,
   app-level dedup by `factID`+`language`).
8. Build passes and the test suite (including new per-language tests) is green in CI.

## Non-goals
- None specified beyond the above.
