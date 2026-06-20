import Foundation
import Observation

/// The download state of one language's On-Demand-Resources pack, as a small explicit state machine.
///
/// Transitions (driven by ``LanguagePackDownloadStore``):
/// ```
/// notRequested ──request──▶ downloading(progress) ──success──▶ available
///                                   │                              ▲
///                                   └──failure──▶ failed(retryable)─┘  (retry → downloading)
/// ```
/// The picker (story 005) observes the fractional `progress` while downloading and the
/// `failed(retryable:)` case to render a retry affordance. ``mappedToPackState`` projects each case
/// onto the existing ``LanguagePackState`` so the provider seam's `state(for:)` contract is unchanged.
enum LanguagePackDownloadState: Equatable {
    /// No download has been requested for this language yet.
    case notRequested
    /// A download is in progress; `progress` is fractional in `0...1`.
    case downloading(progress: Double)
    /// The pack is downloaded and ready to use.
    case available
    /// A download (or post-download validation) attempt failed. `retryable` is `true` when issuing
    /// the request again may succeed (the only failure kind this story produces).
    case failed(retryable: Bool)

    /// Project this download state onto the delivery-agnostic ``LanguagePackState`` the provider seam
    /// exposes, so call sites never branch on ODR specifics.
    var mappedToPackState: LanguagePackState {
        switch self {
        case .notRequested:
            .notDownloaded
        case .downloading:
            .downloading
        case .available:
            .available
        case .failed:
            .failed
        }
    }
}

/// An `@Observable` per-language store of ``LanguagePackDownloadState``, keyed by ``AppLocale``.
///
/// This is the single owner of download state the ODR provider mutates and the picker observes. It is
/// pinned to `@MainActor` because both the provider (which hops to the main actor on ODR completion)
/// and the SwiftUI picker touch it; keeping all reads/writes on the main actor makes the mutable map
/// race-free without locks.
@Observable
@MainActor
final class LanguagePackDownloadStore {
    /// The single app-wide store. The production ``LanguagePackBootstrap`` wires the active
    /// ``ODRLanguagePackProvider`` to this instance, and the language picker (story 005) observes the
    /// same instance — so the picker renders the live download state the provider mutates. Mirrors the
    /// ``LanguageManager/shared`` / `SyncCoordinator` singleton patterns. Tests that need isolation
    /// construct their own store via ``init()`` rather than touching this one.
    static let shared = LanguagePackDownloadStore()

    /// Per-language download state. A language with no entry is treated as ``LanguagePackDownloadState/notRequested``.
    private var statesByCode: [String: LanguagePackDownloadState] = [:]

    init() {}

    /// The current download state for `locale`, defaulting to ``LanguagePackDownloadState/notRequested``.
    func state(for locale: AppLocale) -> LanguagePackDownloadState {
        statesByCode[locale.rawValue] ?? .notRequested
    }

    // MARK: - Transitions

    /// Begin (or restart) a download: move to `downloading(progress: 0)`. Valid from any state, so a
    /// `retry` from `failed` and a fresh request from `notRequested` share this entry point.
    func markDownloading(_ locale: AppLocale, progress: Double = 0) {
        statesByCode[locale.rawValue] = .downloading(progress: clamp(progress))
    }

    /// Update fractional progress while downloading. Ignored unless currently `downloading`, so a
    /// late progress callback after success/failure cannot resurrect a finished download.
    func updateProgress(_ locale: AppLocale, progress: Double) {
        guard case .downloading = state(for: locale) else {
            return
        }
        statesByCode[locale.rawValue] = .downloading(progress: clamp(progress))
    }

    /// Mark the pack available after a successful download (and validation).
    func markAvailable(_ locale: AppLocale) {
        statesByCode[locale.rawValue] = .available
    }

    /// Mark the download failed; `retryable` drives whether the picker offers a retry.
    func markFailed(_ locale: AppLocale, retryable: Bool = true) {
        statesByCode[locale.rawValue] = .failed(retryable: retryable)
    }

    /// Clamp a fractional progress value into `0...1`.
    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
