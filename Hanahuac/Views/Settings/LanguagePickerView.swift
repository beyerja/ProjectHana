import SwiftUI

struct LanguagePickerView: View {
    /// Drives the rows + selection/download actions. Defaults to the shared singletons so the picker
    /// renders the live download state the production ODR provider mutates; a custom view model can be
    /// injected (e.g. previews/tests).
    @State private var viewModel: LanguagePickerViewModel

    init(viewModel: LanguagePickerViewModel = LanguagePickerViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        localeList
            .navigationTitle(L10n["settings.language"])
            .inlineNavigationTitle()
            .onAppear {
                // Carry-over reconciliation: a persisted downloadable selection restored in
                // LanguageManager.init never fired `current`'s didSet, so its ODR download was never
                // kicked off. Re-trigger it here so launch state matches the selection.
                viewModel.reconcileSelectedDownloadOnAppear()
            }
    }

    private var localeList: some View {
        List {
            Section(L10n["settings.language.picker_title"]) {
                ForEach(viewModel.rows) { row in
                    localeRow(row)
                }
            }
        }
    }

    private func localeRow(_ row: LanguagePickerRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                viewModel.select(row.locale)
            } label: {
                HStack {
                    Text(row.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    trailingIndicator(row)
                }
            }
            detail(row)
        }
    }

    @ViewBuilder
    private func trailingIndicator(_ row: LanguagePickerRow) -> some View {
        if row.isSelected, row.state.isReady {
            Image(systemName: "checkmark")
                .foregroundStyle(Color.accentColor)
        } else if row.state.isReady {
            // A downloaded / bundled language ready to select shows no affordance beyond the row tap.
            EmptyView()
        } else if row.state.downloadProgress != nil {
            ProgressView()
                .controlSize(.small)
        } else if case .failed = row.state {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        } else {
            // Downloadable, not yet requested.
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func detail(_ row: LanguagePickerRow) -> some View {
        switch row.state {
        case let .downloading(progress):
            VStack(alignment: .leading, spacing: 2) {
                ProgressView(value: progress)
                Text(L10n["settings.language.downloading"])
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case let .failed(retryable):
            HStack {
                Text(L10n["settings.language.download_failed"])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if retryable {
                    Button(L10n["settings.language.retry"]) {
                        viewModel.retry(row.locale)
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }
        case .bundledAvailable, .available, .downloadable:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        LanguagePickerView()
            .environment(LanguageManager.shared)
    }
}
