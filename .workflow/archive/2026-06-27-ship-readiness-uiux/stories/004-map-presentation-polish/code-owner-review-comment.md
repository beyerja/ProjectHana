<!-- code-owner-review -->
## Code-owner review — APPROVED

Independent second-eye re-verification of the diff (4 files, +42/-8). I reached my own verdict by reading the diff and source directly (not via `/code-review`), distinct from both the implementer and the independent-review agent.

### Hard constraints — independently re-verified
- **Satellite base retained.** `.mapStyle(.imagery(elevation: .flat))` confirmed present in all three views: `MapQuizView.swift:80`, `MapLearningQuizView.swift:102`, `NameFeatureQuizView.swift:241`. The diff does not touch any `mapStyle` line.
- **No place-name labels introduced.** No labeled/`.standard` style, no `showsLabels`/`pointsOfInterest` anywhere in the diff or quiz views.
- **No vector-map redesign.** Changes are purely presentational: corner radius, `.continuous` style, padding, `VStack` spacing.
- **Scope respected.** Overlay-card radius unification, Apple Maps/Legal attribution clearance (`.padding(.bottom, 40)` on feedback banners; `VStack(spacing: 12)` on the Name-Feature body), cross-quiz consistency only.
- **No new unlocalized strings.** Diff adds no string literals or `L10n` keys.

### Reuse note
`Theme.Metrics.cardRadius` (= 18) is a pre-existing constant already used by `HomeView.swift:228`; this PR reuses it for cross-quiz consistency rather than introducing a magic number — a genuine win.

### CI
Required contexts green on head `7638243`: `Build & Test`, `gitleaks` (also `Lint (all languages)`). No event-miss; no self-heal needed.

### Gate
Required `code-owner-review` status check posted **success** on head SHA `76382439351250e4ed6016bd4377cf7dae85ddef` by App `hanahuac-review-bot` (id `4144849`), confirmed via read-back.

Verdict: **APPROVED**.
