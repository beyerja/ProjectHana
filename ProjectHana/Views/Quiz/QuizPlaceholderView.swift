import SwiftUI

struct QuizPlaceholderView: View {
    let category: CardCategory?

    var title: String {
        guard let category else { return "All Categories" }
        switch category {
        case .country:  return "Countries"
        case .river:    return "Rivers"
        case .mountain: return "Mountains"
        case .sea:      return "Seas"
        }
    }

    var body: some View {
        ContentUnavailableView(
            "Quiz Coming Soon",
            systemImage: "questionmark.bubble",
            description: Text("The \(title) quiz will be available in the next update.")
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        QuizPlaceholderView(category: .country)
    }
}
