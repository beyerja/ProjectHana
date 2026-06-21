import SwiftData
import SwiftUI

extension View {
    func withPreviewStore() -> some View {
        modifier(PreviewStoreModifier())
    }
}

private struct PreviewStoreModifier: ViewModifier {
    @State private var provider: CardStoreProvider?
    @State private var statsStore: ProgressStatsStore?

    func body(content: Content) -> some View {
        Group {
            if let provider, let statsStore {
                content
                    .environment(provider)
                    .environment(statsStore)
            } else {
                ProgressView()
            }
        }
        .task {
            guard provider == nil else { return }
            let schema = Schema([ReviewCard.self, DailyProgressSnapshot.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // In-memory preview container creation cannot fail in practice.
            // swiftlint:disable:next force_try
            let container = try! ModelContainer(for: schema, configurations: [config])
            let language = LanguageManager.shared.current.rawValue
            let p = CardStoreProvider(
                modelContext: container.mainContext,
                language: language,
                geographyData: GeographyDataLoader.load()
            )
            p.seedAllModes()
            provider = p
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
