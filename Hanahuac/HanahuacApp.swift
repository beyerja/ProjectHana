import SwiftData
import SwiftUI

@main
struct HanahuacApp: App {
    /// Container creation is delegated to the sync coordinator so the local-only vs CloudKit-backed
    /// configuration is chosen in one place behind a single flag (default OFF → local-only).
    let modelContainer: ModelContainer = SyncCoordinator.makeModelContainer()

    @State private var syncCoordinator = SyncCoordinator()

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
    @State private var cardStore: CardStore?
    @State private var progressStatsStore: ProgressStatsStore?

    var body: some View {
        Group {
            if let store = cardStore, let statsStore = progressStatsStore {
                ContentView()
                    .environment(store)
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
        if cardStore?.language == language, progressStatsStore?.language == language { return }
        let store = CardStore(modelContext: modelContext, language: language)
        let data = GeographyDataLoader.load()
        store.seedIfNeeded(with: data)
        cardStore = store
        progressStatsStore = ProgressStatsStore(modelContext: modelContext, language: language)
    }
}
