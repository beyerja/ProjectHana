# Story 004 — Localize Quiz Prompts and Answer Choices

## Goal
Thread `LanguageManager` through all quiz session factories so that question prompts and answer option labels use localized geographic names.

## Depends On
Stories 001, 002, 003 (infrastructure, UI strings, and localized geo data must all be in place).

## Background
Quiz sessions currently construct English-only prompts by interpolating raw `name` fields. For example:
- `MultipleChoiceSession.countryCapitalQuestions`: `"What is the capital of \(country.name)?"`
- `MultipleChoiceSession.continentQuestions`: `"On which continent is \(factName(fact)) located?"`
- `TextQuizSession` (capital quiz): prompts reference country names and capitals
- `MapQuizSession`: may use country names in labels

All of these need to use `localizedName(for:)` (from story 003) for geographic names and localized string keys (from story 002) for template text.

## Tasks

### 1. Update `MultipleChoiceSession` factory methods
`ProjectHana/Views/Quiz/MultipleChoice/MultipleChoiceSession.swift`

Add `locale: AppLocale` parameter to each factory method:
- `countryCapitalQuestions(cards:countries:locale:)` — use `country.localizedName(for: locale)` in prompt; use `country.localizedCapital(for: locale)` as option labels
- `continentQuestions(cards:facts:...:locale:)` — use `factLocalizedName(for: locale)` in prompt; translate continent option labels via `Localizable.strings`
- `seaIdentificationQuestions(cards:seas:locale:)` — use `sea.localizedName(for: locale)` as option labels

Prompt templates ("What is the capital of %@?", "On which continent is %@ located?") should use localized string keys with `%@` placeholders.

### 2. Update `TextQuizSession`
`ProjectHana/Views/Quiz/TextQuiz/TextQuizSession.swift`

Thread `locale: AppLocale` through question generation so:
- "What is the capital of X?" uses the localized country name
- "Which country has X as its capital?" uses the localized capital name
- Answer validation accepts the localized name (or the canonical English name as fallback)

### 3. Update `MapQuizSession`
`ProjectHana/Views/Quiz/MapQuiz/MapQuizSession.swift`

If country names appear in any labels (e.g., the question text or result feedback), use `localizedName(for:)`.

### 4. Update call sites to pass locale
Wherever session factories are called (in views), read `LanguageManager.current` from the environment and pass it to the factory. Example in `MultipleChoiceQuizView`:
```swift
@Environment(LanguageManager.self) private var languageManager
// ...
let questions = MultipleChoiceSession.countryCapitalQuestions(
    cards: ..., countries: ..., locale: languageManager.current
)
```

### 5. Add quiz prompt string keys to `Localizable.strings`
- `quiz.prompt.capital_of` → "What is the capital of %@?" (all four languages)
- `quiz.prompt.continent_of` → "On which continent is %@ located?" (all four languages)
- `quiz.prompt.country_of_capital` → "Which country has %@ as its capital?" (all four languages)
- Continent names (may already be done in story 003)

## Acceptance Criteria
- [ ] In French mode: a Countries quiz shows "Quelle est la capitale de l'Allemagne ?" with "Berlin" as the answer option
- [ ] In German mode: a Rivers quiz shows the German river name in the prompt
- [ ] In Spanish mode: continent options are in Spanish
- [ ] Switching language in the picker immediately affects new quiz sessions (existing in-progress sessions are unaffected)
- [ ] English mode is unchanged from pre-feature behaviour

## Files Touched
- `ProjectHana/Views/Quiz/MultipleChoice/MultipleChoiceSession.swift`
- `ProjectHana/Views/Quiz/MultipleChoice/MultipleChoiceQuizView.swift`
- `ProjectHana/Views/Quiz/TextQuiz/TextQuizSession.swift`
- `ProjectHana/Views/Quiz/TextQuiz/CapitalQuizView.swift`
- `ProjectHana/Views/Quiz/MapQuiz/MapQuizSession.swift`
- `ProjectHana/Views/Quiz/MapQuiz/MapQuizView.swift`
- All four `Localizable.strings` files (quiz prompt keys)
