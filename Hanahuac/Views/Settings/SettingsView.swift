import SwiftUI

/// The app's settings surface. Hosts the language picker entry point and the opt-in iCloud Sync
/// toggle + status indicator. Bound to `SyncCoordinator` (the sync state owner); it does not
/// implement sync itself.
struct SettingsView: View {
    @Environment(SyncCoordinator.self) private var sync

    var body: some View {
        @Bindable var sync = sync
        List {
            Section(L10n["settings.section.general"]) {
                NavigationLink {
                    LanguagePickerView()
                } label: {
                    HStack {
                        Text(L10n["settings.language"])
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .accessibilityIdentifier("settings.language")
            }

            Section {
                Toggle(isOn: Binding(
                    get: { sync.userOptedIn },
                    set: { sync.setOptIn($0) }
                )) {
                    Text(L10n["settings.sync.toggle"])
                }
                .accessibilityIdentifier("settings.syncToggle")
                .disabled(!SyncStatusPresentation.isToggleEnabled(for: sync.status))

                HStack {
                    Text(L10n["settings.sync.status_label"])
                    Spacer()
                    Text(L10n[SyncStatusPresentation.labelKey(for: sync.status)])
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(L10n["settings.section.icloud"])
            } footer: {
                if let key = SyncStatusPresentation.footnoteKey(for: sync.status) {
                    Text(L10n[key])
                }
            }
        }
        .navigationTitle(L10n["settings.title"])
        .inlineNavigationTitle()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(LanguageManager.shared)
            .environment(SyncCoordinator(
                availability: FixedICloudAvailabilityProvider(isICloudAccountAvailable: false)
            ))
    }
}
