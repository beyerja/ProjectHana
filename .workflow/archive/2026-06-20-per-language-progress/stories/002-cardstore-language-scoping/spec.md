# Story 002 — Scope CardStore (spaced-repetition state) per language

## Goal
Make `CardStore` operate on the active language only: every fetch, seed, upsert, reset, and dedup
is scoped to a language. Two languages can hold a `ReviewCard` for the same `factID` without
collision. Depends on Story 001's `ReviewCard.language` column.

## Design
- Give `CardStore` an active language (an `AppLocale`/`String`), injected at construction. The app
  passes `LanguageManager.shared.current`; tests can pass any locale.
- Scope all queries: `allCards`, `dueCards`, `newCards`, `ensureGraduationConsistency` only see
  cards whose `language` matches the active language. (Filter in-memory after fetch, or via predicate
  — keep it correct and simple.)
- `seedIfNeeded(with:)` stamps newly-inserted `ReviewCard`s with the active language and only seeds
  factIDs missing *for that language*. Seeding language A must not seed/touch language B.
- `upsert`/`resetAll` operate within the active language. `resetAll` must not wipe other languages.
- `deduplicate()` groups by (`factID`, `language`) — a `factID` present in two languages is NOT a
  duplicate; same `factID` twice in the same language still collapses to the most-progressed card.
- Reflect the active language in `seedIfNeeded` so the flexible-fact-set requirement holds: a fact
  absent in a language simply gets no card there (no assumption all languages share the fact set).
- Update call sites that construct `CardStore` (`HanahuacApp.AppRootView`) to pass the active
  language, and ensure the store is rebuilt / re-scoped when the language changes (so switching
  EN→KO shows a fresh Korean track and back-to-EN restores English). A clean approach: observe
  `LanguageManager.current` and rebuild `CardStore` (+ re-seed) on change.

## Acceptance Criteria
1. `CardStore` is constructed with an active language and all its reads/writes are scoped to it.
2. Seeding language A creates one card per fact for A only; language B is untouched. Re-seeding is
   idempotent per language.
3. `deduplicate()` keys on (`factID`, `language`): the same `factID` in two languages coexists; a
   true same-language duplicate still collapses to the most-progressed card.
4. Switching the active language swaps the visible card track and leaves other languages' cards
   intact; switching back restores the original track exactly (covered by a test).
5. Build passes; new + existing `CardStore`/dedup tests are green.
