import SwiftUI

struct QuizModePickerView: View {
    @Environment(CardStore.self) private var cardStore
    @Environment(\.dismiss) private var dismiss

    private var dueCount: Int { cardStore.dueCards(for: .country).count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                NavigationLink {
                    MapQuizView(category: .country)
                } label: {
                    modeCard(
                        icon: "map.fill",
                        color: .blue,
                        title: "Map Tap Quiz",
                        description: "Tap the correct country on the map"
                    )
                }

                NavigationLink {
                    CapitalQuizView(mode: .capitalOfCountry)
                } label: {
                    modeCard(
                        icon: "building.columns.fill",
                        color: .purple,
                        title: "Type the Capital",
                        description: "\"What is the capital of X?\""
                    )
                }

                NavigationLink {
                    CapitalQuizView(mode: .countryOfCapital)
                } label: {
                    modeCard(
                        icon: "globe.europe.africa.fill",
                        color: .indigo,
                        title: "Name the Country",
                        description: "\"Which country has X as its capital?\""
                    )
                }

                NavigationLink {
                    MultipleChoiceQuizView(category: .country)
                } label: {
                    modeCard(
                        icon: "list.bullet.circle.fill",
                        color: .orange,
                        title: "Multiple Choice",
                        description: "Pick the capital from 4 options"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Countries")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("\(dueCount)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text(dueCount == 1 ? "card due" : "cards due")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func modeCard(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        QuizModePickerView()
            .withPreviewStore()
    }
}
