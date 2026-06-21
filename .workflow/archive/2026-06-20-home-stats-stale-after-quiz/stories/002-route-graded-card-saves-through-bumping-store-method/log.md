# Log — Route quiz graded-card saves through a bumping store method
2026-06-20 break-tasks: DONE, 9 tasks
2026-06-20 implement-story: DONE — all 9 tasks; added CardStore.persistCardChanges(), routed all 6 quiz views through it, wired CardStore into the two learning views, added 2 tests; lint + test pass
2026-06-20 verify-story: DONE — all 6 quiz views (MultipleChoice, MapQuiz, Capital, NameFeature, Learning, MapLearning) call cardStore.persistCardChanges() after grading; persistCardChanges() saves then markChanged(); no bare modelContext.save() in any quiz view (all .save() confined to stores/PreviewStore); SR grading unchanged; CardStoreTests has testPersistCardChangesBumpsRevision + testPersistCardChangesPersistsCardMutation; lint + test pass
