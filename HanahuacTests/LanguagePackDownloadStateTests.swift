import XCTest
@testable import Hanahuac

/// Pure-logic tests for the ``LanguagePackDownloadState`` machine and its `@MainActor`
/// ``LanguagePackDownloadStore``: every transition (request → progress → success;
/// request → failure → retry → …) and the projection onto ``LanguagePackState``.
@MainActor
final class LanguagePackDownloadStateTests: XCTestCase {
    // MARK: - State → LanguagePackState projection

    func testMappedToPackState_coversEveryCase() {
        XCTAssertEqual(LanguagePackDownloadState.notRequested.mappedToPackState, .notDownloaded)
        XCTAssertEqual(LanguagePackDownloadState.downloading(progress: 0.3).mappedToPackState, .downloading)
        XCTAssertEqual(LanguagePackDownloadState.available.mappedToPackState, .available)
        XCTAssertEqual(LanguagePackDownloadState.failed(retryable: true).mappedToPackState, .failed)
    }

    // MARK: - Default state

    func testStore_defaultsToNotRequested() {
        let store = LanguagePackDownloadStore()
        XCTAssertEqual(store.state(for: .fr), .notRequested)
    }

    // MARK: - request → progress → success

    func testTransition_request_progress_success() {
        let store = LanguagePackDownloadStore()

        store.markDownloading(.fr)
        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 0))

        store.updateProgress(.fr, progress: 0.25)
        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 0.25))

        store.updateProgress(.fr, progress: 0.9)
        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 0.9))

        store.markAvailable(.fr)
        XCTAssertEqual(store.state(for: .fr), .available)
    }

    // MARK: - request → failure → retry → success

    func testTransition_request_failure_retry() {
        let store = LanguagePackDownloadStore()

        store.markDownloading(.de)
        store.markFailed(.de)
        XCTAssertEqual(store.state(for: .de), .failed(retryable: true))

        // retry re-enters downloading…
        store.markDownloading(.de)
        XCTAssertEqual(store.state(for: .de), .downloading(progress: 0))

        // …and can then succeed.
        store.markAvailable(.de)
        XCTAssertEqual(store.state(for: .de), .available)
    }

    // MARK: - progress is clamped and only applies while downloading

    func testUpdateProgress_clampsToUnitInterval() {
        let store = LanguagePackDownloadStore()
        store.markDownloading(.fr)

        store.updateProgress(.fr, progress: 1.7)
        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 1))

        store.updateProgress(.fr, progress: -0.5)
        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 0))
    }

    func testUpdateProgress_isIgnoredWhenNotDownloading() {
        let store = LanguagePackDownloadStore()

        // No effect from notRequested.
        store.updateProgress(.fr, progress: 0.5)
        XCTAssertEqual(store.state(for: .fr), .notRequested)

        // A late progress callback after success cannot resurrect a finished download.
        store.markAvailable(.fr)
        store.updateProgress(.fr, progress: 0.5)
        XCTAssertEqual(store.state(for: .fr), .available)
    }

    // MARK: - per-language isolation

    func testStates_areIndependentPerLanguage() {
        let store = LanguagePackDownloadStore()
        store.markDownloading(.fr, progress: 0.4)
        store.markFailed(.de)

        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 0.4))
        XCTAssertEqual(store.state(for: .de), .failed(retryable: true))
        XCTAssertEqual(store.state(for: .ko), .notRequested)
    }
}
