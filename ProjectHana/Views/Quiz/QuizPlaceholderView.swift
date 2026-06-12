import SwiftUI

struct QuizPlaceholderView: View {
    let category: CardCategory?

    var title: String {
        guard let category else { return L10n["quiz_placeholder.all_categories"] }
        return category.displayName
    }

    var body: some View {
        ContentUnavailableView(
            L10n["quiz_placeholder.coming_soon"],
            systemImage: "questionmark.bubble",
            description: Text(String(format: L10n["quiz_placeholder.desc"], title))
        )
        .navigationTitle(title)
        .inlineNavigationTitle()
    }
}

#Preview {
    NavigationStack {
        QuizPlaceholderView(category: .country)
    }
}
