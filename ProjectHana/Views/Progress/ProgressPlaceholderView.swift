import SwiftUI

struct ProgressPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Progress Coming Soon",
            systemImage: "chart.bar",
            description: Text("Your learning stats will appear here.")
        )
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProgressPlaceholderView()
    }
}
