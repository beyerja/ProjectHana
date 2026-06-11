import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    categoryGrid
                    progressLink
                }
                .padding()
            }
            .navigationTitle("ProjectHana")
            .largeNavigationTitle()
        }
    }

    // MARK: – Category grid

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                categoryTile(title: "Countries", icon: "globe",       color: .blue,  category: .country)
                categoryTile(title: "Rivers",    icon: "water.waves", color: .cyan,  category: .river)
                categoryTile(title: "Mountains", icon: "mountain.2",  color: .brown, category: .mountain)
                categoryTile(title: "Seas",      icon: "drop.fill",   color: .teal,  category: .sea)
            }
        }
    }

    private func categoryTile(title: String, icon: String, color: Color, category: CardCategory) -> some View {
        NavigationLink {
            CategoryDetailView(category: category)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline).bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(color)
        }
    }

    // MARK: – Progress link

    private var progressLink: some View {
        NavigationLink {
            StatsView()
        } label: {
            Label("View Progress", systemImage: "chart.bar.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    HomeView()
        .withPreviewStore()
}
