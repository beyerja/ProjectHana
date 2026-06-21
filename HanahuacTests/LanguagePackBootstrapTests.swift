import XCTest
@testable import Hanahuac

/// Verifies the production composition root (``LanguagePackBootstrap``) actually installs an
/// ``ODRLanguagePackProvider`` as the active provider, so the selection-path hook
/// ``LanguagePackProviderHolder/requestDownloadIfNeeded(for:)`` (driven by `LanguageManager.current`)
/// drives a real ODR download instead of downcasting to `nil`.
///
/// Uses a fake ``ResourceRequesting`` seam — NO live network.
@MainActor
final class LanguagePackBootstrapTests: XCTestCase {
    private var savedProvider: LanguagePackProvider!

    override func setUp() {
        super.setUp()
        savedProvider = LanguagePackProviderHolder.active
    }

    override func tearDown() {
        LanguagePackProviderHolder.active = savedProvider
        super.tearDown()
    }

    /// A hand-driven ``ResourceRequesting`` that records that a download was begun — no real
    /// `NSBundleResourceRequest`, no network.
    private final class FakeResourceRequest: ResourceRequesting {
        let tags: Set<String>
        var loadingProgress: Double = 0
        private(set) var beginCount = 0

        init(tags: Set<String>) {
            self.tags = tags
        }

        func observeProgress(_: @escaping (Double) -> Void) {}

        func conditionallyBeginAccessingResources(completionHandler: @escaping (Bool) -> Void) {
            completionHandler(false)
        }

        func beginAccessingResources(completionHandler _: @escaping (Error?) -> Void) {
            beginCount += 1
        }

        func endAccessingResources() {}
    }

    /// A factory that records every request it hands out, so a test can assert a download was issued.
    private final class FakeFactory {
        private(set) var made: [FakeResourceRequest] = []

        func make(_ tags: Set<String>) -> ResourceRequesting {
            let request = FakeResourceRequest(tags: tags)
            made.append(request)
            return request
        }
    }

    // MARK: - the install makes the holder downcast succeed and issues a request

    func testInstall_makesHolderRequestDownloadDriveODRPath() throws {
        let factory = FakeFactory()
        let store = LanguagePackDownloadStore()

        let installed = LanguagePackBootstrap.install(store: store, makeRequest: factory.make)

        // The active provider is now the ODR provider (the downcast the holder performs is no longer nil).
        let active = try XCTUnwrap(
            LanguagePackProviderHolder.active as? ODRLanguagePackProvider,
            "bootstrap must install the ODR provider as active"
        )
        XCTAssertIdentical(active, installed)

        // Selecting a downloadable language through the holder hook drives a real request via the seam.
        LanguagePackProviderHolder.requestDownloadIfNeeded(for: .fr)

        XCTAssertEqual(factory.made.count, 1, "selecting a downloadable language must issue one ODR request")
        let request = try XCTUnwrap(factory.made.last)
        XCTAssertEqual(request.tags, ["lang-fr"], "request is keyed off the language's ODR tag")
        XCTAssertEqual(request.beginCount, 1, "the download was begun through the ResourceRequesting seam")
        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 0), "store reflects the in-flight download")
    }

    // MARK: - base languages still never issue a request through the installed provider

    func testInstall_baseLanguageIssuesNoRequest() {
        let factory = FakeFactory()
        let store = LanguagePackDownloadStore()
        LanguagePackBootstrap.install(store: store, makeRequest: factory.make)

        LanguagePackProviderHolder.requestDownloadIfNeeded(for: .en)

        XCTAssertTrue(factory.made.isEmpty, "base languages must never issue an ODR request after bootstrap")
    }
}
