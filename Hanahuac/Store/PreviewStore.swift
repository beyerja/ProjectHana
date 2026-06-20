import SwiftData
import SwiftUI

extension View {
    func withPreviewStore() -> some View {
        modifier(PreviewStoreModifier())
    }
}

private struct PreviewStoreModifier: ViewModifier {
    @State private var store: CardStore?
    @State private var statsStore: ProgressStatsStore?

    func body(content: Content) -> some View {
        Group {
            if let store, let statsStore {
                content
                    .environment(store)
                    .environment(statsStore)
            } else {
                ProgressView()
            }
        }
        .task {
            guard store == nil else { return }
            let schema = Schema([ReviewCard.self, DailyProgressSnapshot.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // In-memory preview container creation cannot fail in practice.
            // swiftlint:disable:next force_try
            let container = try! ModelContainer(for: schema, configurations: [config])
            let language = LanguageManager.shared.current.rawValue
            let s = CardStore(modelContext: container.mainContext, language: language)
            s.seedIfNeeded(with: GeographyDataLoader.load())
            store = s
            let stats = ProgressStatsStore(modelContext: container.mainContext, language: language)
            #if DEBUG
                for snapshot in DailyProgressSnapshot.sampleHistory() {
                    snapshot.language = language
                    container.mainContext.insert(snapshot)
                }
                try? container.mainContext.save()
            #endif
            statsStore = stats
        }
    }
}
