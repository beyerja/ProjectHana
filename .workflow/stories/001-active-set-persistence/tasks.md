## Tasks

- [x] 001: Create `ActiveSetStore` protocol + `UserDefaultsActiveSetStore` implementation — a thin persistence layer keyed by `CardCategory` that stores/retrieves an ordered array of `factID` strings
- [x] 002: Update `LearningSession.init(newCards:category:store:)` to accept a category and an `ActiveSetStore` — on init, load persisted IDs, filter to still-ungraduated cards, use them as `activeSet`; if none remain, draw a fresh 10 and persist them
- [x] 003: Update `LearningSession.graduate(_:)` to call `store.save(activeSet)` after each graduation (so the stored IDs reflect current active set membership)
- [x] 004: Update `LearningQuizView` and `CategoryDetailView` to pass `category` to `LearningSession.init` (using the default `UserDefaultsActiveSetStore`)
- [x] 005: Wire pbxproj — add `ActiveSetStore.swift` to the Xcode project build phases
