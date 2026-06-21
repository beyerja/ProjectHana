import Foundation

/// The picker's per-language render state: a pure projection of ``LanguagePackDownloadState`` plus the
/// language's bundled-vs-downloadable nature onto the cases the language picker draws.
///
/// This is intentionally free of any SwiftUI dependency so it is unit-testable in isolation (story 005
/// tests drive it straight off a ``LanguagePackDownloadStore`` with no live network). It does NOT
/// duplicate the download state machine — it reuses ``LanguagePackDownloadState`` via ``from(_:isBase:)``
/// and only re-shapes it for presentation:
/// - ``bundledAvailable`` — a base language (en, es-MX): always selectable, no download affordance.
/// - ``available`` — a downloadable pack already on device: selectable, no re-download prompt.
/// - ``downloadable`` — a downloadable pack not yet requested: selecting it triggers the lazy download.
/// - ``downloading`` — a download in progress; `progress` is fractional in `0...1` for a determinate bar.
/// - ``failed`` — a download/validation failure; `retryable` drives whether the picker offers retry.
enum LanguagePackRowState: Equatable {
    /// A bundled base language (en, es-MX): immediately available, never downloaded.
    case bundledAvailable
    /// A downloadable pack that is already downloaded and ready.
    case available
    /// A downloadable pack with no download requested yet (selecting it kicks one off).
    case downloadable
    /// A download in progress; `progress` is fractional in `0...1`.
    case downloading(progress: Double)
    /// A failed download; `retryable` indicates a retry may succeed.
    case failed(retryable: Bool)

    /// Project a ``LanguagePackDownloadState`` onto a picker row state. `isBase` is the language's
    /// ``AppLocale/isBundledBaseLanguage``: base languages always render as ``bundledAvailable``
    /// regardless of any (never-issued) download state.
    static func from(_ downloadState: LanguagePackDownloadState, isBase: Bool) -> LanguagePackRowState {
        if isBase {
            return .bundledAvailable
        }
        switch downloadState {
        case .notRequested:
            return .downloadable
        case let .downloading(progress):
            return .downloading(progress: progress)
        case .available:
            return .available
        case let .failed(retryable):
            return .failed(retryable: retryable)
        }
    }

    /// Whether this language is ready to use right now (base or a downloaded pack), so the picker can
    /// draw the selected/available checkmark without re-deriving the cases.
    var isReady: Bool {
        switch self {
        case .bundledAvailable, .available:
            true
        case .downloadable, .downloading, .failed:
            false
        }
    }

    /// Whether the picker should offer a retry action for this row (a retryable failure).
    var canRetry: Bool {
        if case let .failed(retryable) = self {
            return retryable
        }
        return false
    }

    /// The in-progress download fraction (`0...1`) when downloading, else `nil` — so a view can bind a
    /// determinate `ProgressView(value:)` only while a download is running.
    var downloadProgress: Double? {
        if case let .downloading(progress) = self {
            return progress
        }
        return nil
    }
}
