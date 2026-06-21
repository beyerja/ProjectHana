import Foundation
import Observation

/// One row the language picker renders: the language, its native display name, its current
/// ``LanguagePackRowState``, and whether it is the active selection.
struct LanguagePickerRow: Identifiable, Equatable {
    /// Stable identity for SwiftUI `ForEach` — the language code.
    var id: String {
        locale.rawValue
    }

    /// The language this row represents.
    let locale: AppLocale
    /// The language's native display name (e.g. "Français", "한국어").
    let displayName: String
    /// The presentation state (bundled/available/downloadable/downloading/failed).
    let state: LanguagePackRowState
    /// Whether this language is the currently selected one in ``LanguageManager``.
    let isSelected: Bool
}

/// Drives the language picker (story 005): enumerates languages from the data-driven catalog (story
/// 001), reads each language's live download state from the shared ``LanguagePackDownloadStore`` (story
/// 004), and projects them into ``LanguagePickerRow`` render models. It delegates all download
/// triggering and retry to the story-004 ``LanguagePackProviderHolder`` seams — it never reimplements
/// the ODR mechanism.
///
/// `@Observable` so the SwiftUI picker re-renders when the store mutates (the store is itself
/// `@Observable`, and reading it inside `rows` registers the dependency). `@MainActor` because it reads
/// the main-actor store and drives the main-actor provider hooks.
@Observable
@MainActor
final class LanguagePickerViewModel {
    /// The selection owner; reading `current` reflects the active language and setting it persists +
    /// (for the bundled provider, a no-op; for ODR) triggers the download via its `didSet`.
    @ObservationIgnored private let languageManager: LanguageManager

    /// The observable per-language download-state store the rows project. Defaults to the shared
    /// instance the production ODR provider mutates, so the picker renders live state.
    @ObservationIgnored private let store: LanguagePackDownloadStore

    /// - Parameters:
    ///   - languageManager: the selection owner. Defaults to the shared singleton.
    ///   - store: the observable download-state store. Defaults to the shared singleton.
    nonisolated init(
        languageManager: LanguageManager = .shared,
        store: LanguagePackDownloadStore = .shared
    ) {
        self.languageManager = languageManager
        self.store = store
    }

    /// The currently selected language.
    var selected: AppLocale {
        languageManager.current
    }

    /// One ``LanguagePickerRow`` per catalog language, in catalog order, with each row's live download
    /// state projected onto a ``LanguagePackRowState``. Reading `store.state(for:)` here registers the
    /// observation dependency so the picker re-renders as downloads progress.
    var rows: [LanguagePickerRow] {
        LanguageCatalog.all.compactMap { descriptor in
            guard let locale = AppLocale(rawValue: descriptor.code) else {
                return nil
            }
            let rowState = LanguagePackRowState.from(
                store.state(for: locale),
                isBase: locale.isBundledBaseLanguage
            )
            return LanguagePickerRow(
                locale: locale,
                displayName: descriptor.displayName,
                state: rowState,
                isSelected: locale == languageManager.current
            )
        }
    }

    /// Select `locale`: persist it as the active language (which switches UI strings + geo names) and,
    /// for a not-yet-downloaded downloadable pack, lazily trigger its ODR download. Setting
    /// ``LanguageManager/current`` already calls ``LanguagePackProviderHolder/requestDownloadIfNeeded(for:)``
    /// via its `didSet`, but that hop is async; we also request synchronously here so the row reflects
    /// `downloading` immediately on tap (the request coalesces, so the double call issues one download).
    func select(_ locale: AppLocale) {
        languageManager.current = locale
        LanguagePackProviderHolder.requestDownloadIfNeeded(for: locale)
    }

    /// Re-issue the download for a previously-failed downloadable language, delegating to the story-004
    /// retry seam. A no-op for base languages / non-ODR providers.
    func retry(_ locale: AppLocale) {
        LanguagePackProviderHolder.retryDownload(for: locale)
    }

    /// Carry-over launch reconciliation (task 005). ``LanguageManager/init`` restores a persisted
    /// selection by assigning `current` directly, which does NOT fire its `didSet` — so a previously
    /// selected downloadable language never had its ODR download kicked off at launch. Call this on the
    /// picker's appear (and it is safe to call any time) to (re-)trigger the download for the selected
    /// language when its pack is downloadable and not yet available. The request coalesces, so an
    /// already-in-flight or already-available pack is untouched.
    func reconcileSelectedDownloadOnAppear() {
        let locale = languageManager.current
        guard !locale.isBundledBaseLanguage else {
            return
        }
        switch store.state(for: locale) {
        case .notRequested, .failed:
            LanguagePackProviderHolder.requestDownloadIfNeeded(for: locale)
        case .downloading, .available:
            break
        }
    }
}
