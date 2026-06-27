<!-- code-owner-review -->
## Code-owner review — APPROVED

Independent confirming pass (no `/code-review` re-run) on head `c366861`. I reached my own verdict and posted the required `code-owner-review` status check (conclusion `success`, App id `4144849`) on the head SHA, with read-back proof.

### Verified independently
- **AC3 — Settings chevron** (`SettingsView.swift`): redundant manual `chevron.right` removed; the `NavigationLink` renders exactly one disclosure chevron. Correct.
- **AC4 — Map-learning back button** (`MapLearningQuizView.swift`): system back button hidden; single crisp custom `chevron.backward` toolbar item gated by `showsBackButton` (`session?.isFinished != true`), so it is hidden on the completion screen. Wired into `body`. Correct.
- **AC7 — Progress table** (`StatsView.swift`): new `MasteryTier.localizedName` drives visible column labels + accessibility labels in the header, per-cell `"<tier>: <count>"` a11y labels in rows, and the legend (replacing the hardcoded `rawValue`). All in live view code.
- **L10n**: 5 keys (`stats.tier.name.{new,learning,review,mastered}`, `a11y.back`) added to all 21 locales with genuine per-locale translations. `Lint (all languages)` is green.
- **AC9**: `003-ui-polish.json` walkthrough script present, exercising Settings/Map/Progress with screenshots + dumps; uses the `BackButton` identifier matching the new accessibilityIdentifier.

CI is fully green on the head SHA (`Build & Test`, `gitleaks`, `Lint (all languages)`). independent-review previously APPROVED; I concur on my own assessment.

Gate check posted on `c36686175d279eea83e05d2b7fdcc811f6ed3d22` — read-back: `{conclusion: success, app_id: 4144849}`.
