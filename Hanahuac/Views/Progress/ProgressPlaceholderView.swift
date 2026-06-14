import SwiftUI

struct ProgressPlaceholderView: View {
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        ContentUnavailableView(
            L10n["progress.coming_soon"],
            systemImage: "chart.bar",
            description: Text(L10n["progress.placeholder_desc"])
        )
        .navigationTitle(L10n["progress.title"])
        .inlineNavigationTitle()
        .id(languageManager.current)
    }
}

#Preview {
    NavigationStack {
        ProgressPlaceholderView()
    }
}
