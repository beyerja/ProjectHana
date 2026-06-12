import SwiftUI

struct LanguagePickerView: View {
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        localeList
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var localeList: some View {
        List {
            ForEach(AppLocale.allCases, id: \.rawValue) { locale in
                localRow(locale)
            }
        }
    }

    private func localRow(_ locale: AppLocale) -> some View {
        Button {
            languageManager.current = locale
        } label: {
            HStack {
                Text(locale.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                if languageManager.current == locale {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LanguagePickerView()
            .environment(LanguageManager.shared)
    }
}
