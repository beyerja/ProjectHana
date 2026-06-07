import SwiftUI
import SwiftData

extension View {
    func withPreviewStore() -> some View {
        modifier(PreviewStoreModifier())
    }
}

private struct PreviewStoreModifier: ViewModifier {
    @State private var store: CardStore?

    func body(content: Content) -> some View {
        Group {
            if let store {
                content.environment(store)
            } else {
                ProgressView()
            }
        }
        .task {
            guard store == nil else { return }
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: ReviewCard.self, configurations: config)
            let s = CardStore(modelContext: container.mainContext)
            s.seedIfNeeded(with: GeographyDataLoader.load())
            store = s
        }
    }
}
