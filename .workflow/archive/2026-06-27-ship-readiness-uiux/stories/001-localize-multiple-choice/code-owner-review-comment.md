<!-- code-owner-review -->
## Code-owner review — APPROVED

Independent confirming pass (diff read directly, not via `/code-review`). I formed my own verdict
rather than rubber-stamping the `independent-review` APPROVED.

**Verified independently**
- **AC1 production reachability:** the active locale is threaded through *both* MC entry points.
  `MultipleChoiceQuizView.buildSession` (review MC) already passed `locale`; this PR fixes the gap in
  `LearningQuizView.makeQuestion` (new-card MC), which previously defaulted to `.en` and leaked English.
  Both now pass `locale` + `factLocalizedName` into the `MultipleChoiceSession` factories; factory
  signatures match the call sites. Sea prompt + cardinal directions resolve via `L10n.string`.
- **AC3:** `just l10n-check` PASS — 161 canonical keys across all required FULL/BASE locales; the new
  `quiz.prompt.sea_location` + `quiz.region.{north,south,east,west}` keys present in every locale.
- **l10n duplicate allowlist** additions are legitimate (single-letter compass abbreviations genuinely
  identical to English in several languages), not untranslated stubs.
- **CI on head `f3b44f8`:** `Build & Test`, `Lint`, `gitleaks` all green.
- Correctness sweep: format strings each use one `%@`; the `makeQuestion` switch correctly gains
  `return` on every arm now that it is multi-statement.

Gate check `code-owner-review` posted `success` on head `f3b44f8` (app id 4144849), read-back confirmed.

**Verdict: APPROVED.**
