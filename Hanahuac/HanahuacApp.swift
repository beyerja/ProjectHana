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
    @State private var cardStore: CardStore?

    var body: some View {
        Group {
            if let store = cardStore {
                ContentView()
                    .environment(store)
            } else {
                ProgressView("Loading…")
            }
        }
        .onAppear {
            guard cardStore == nil else { return }
            let store = CardStore(modelContext: modelContext)
            let data = GeographyDataLoader.load()
            store.seedIfNeeded(with: data)
            cardStore = store
        }
    }
}
