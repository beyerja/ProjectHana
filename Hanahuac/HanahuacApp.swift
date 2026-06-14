import SwiftUI
import SwiftData

@main
struct HanahuacApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema changed without a migration plan — wipe the store and start fresh.
            // All data is re-seeded from bundled JSON on next launch.
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
            }
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(LanguageManager.shared)
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
