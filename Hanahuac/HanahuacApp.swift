import SwiftData
import SwiftUI

@main
struct HanahuacApp: App {
    /// Container creation is delegated to the sync coordinator so the local-only vs CloudKit-backed
    /// configuration is chosen in one place behind a single flag (default OFF → local-only).
    let modelContainer: ModelContainer = SyncCoordinator.makeModelContainer()

    @State private var syncCoordinator = SyncCoordinator()

    init() {
        // Install the On-Demand-Resources provider as the active language-pack provider, backed by the
        // shared download store the picker observes. Without this, selecting a downloadable language
        // would never trigger an ODR download (the holder's downcast would always be nil). `App.init`
        // runs on the main actor, matching `requestDownloadIfNeeded`/the store's `@MainActor` isolation.
        LanguagePackBootstrap.installForProduction()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(LanguageManager.shared)
                .environment(syncCoordinator)
        }
        .modelContainer(modelContainer)
    }
}

private struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @State private var cardStoreProvider: CardStoreProvider?
    @State private var progressStatsStore: ProgressStatsStore?

    var body: some View {
        Group {
            if let provider = cardStoreProvider, let statsStore = progressStatsStore {
                ContentView()
                    .environment(provider)
                    .environment(statsStore)
                    // Re-key on the active language so SwiftUI tears down and rebuilds the subtree
                    // (and its @State sessions) when the user switches languages — the new
                    // language's track is shown fresh and the previous one is left untouched.
                    .id(languageManager.current.rawValue)
            } else {
                ProgressView("Loading…")
            }
        }
        .onAppear { rebuildStores(for: languageManager.current) }
        // Rebuild the language-scoped stores whenever the active language changes so progress for
        // each language stays fully independent and persistent.
        .onChange(of: languageManager.current) { _, newLocale in
            rebuildStores(for: newLocale)
        }
    }

    private func rebuildStores(for locale: AppLocale) {
        let language = locale.rawValue
        // Skip if the stores already reflect the active language (avoids redundant re-seeding).
        if cardStoreProvider?.language == language, progressStatsStore?.language == language { return }
        // One-time upgrade migration: attribute pre-existing global progress to the active language
        // and (per-quiz-mode story) the legacy Map Tab Quiz mode. Runs before seeding so it never
        // races empty-language/empty-quizMode rows that seeding would create.
        ProgressMigrator.migrateIfNeeded(context: modelContext, activeLanguage: language)
        let data = GeographyDataLoader.load()
        // One CardStore per quiz mode, scoped to (language, mode); each is seeded for the categories
        // its mode serves so progress is independent per mode.
        let provider = CardStoreProvider(modelContext: modelContext, language: language, geographyData: data)
        provider.seedAllModes()
        cardStoreProvider = provider
        progressStatsStore = ProgressStatsStore(modelContext: modelContext, language: language)
    }
}
