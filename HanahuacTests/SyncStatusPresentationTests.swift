import XCTest
@testable import Hanahuac

final class SyncStatusPresentationTests: XCTestCase {

    func testLabelKeyForEachStatus() {
        XCTAssertEqual(SyncStatusPresentation.labelKey(for: .off), "settings.sync.status.off")
        XCTAssertEqual(SyncStatusPresentation.labelKey(for: .unavailable), "settings.sync.status.unavailable")
        XCTAssertEqual(SyncStatusPresentation.labelKey(for: .on), "settings.sync.status.on")
        XCTAssertEqual(SyncStatusPresentation.labelKey(for: .syncing), "settings.sync.status.syncing")
        XCTAssertEqual(SyncStatusPresentation.labelKey(for: .idle), "settings.sync.status.idle")
        XCTAssertEqual(SyncStatusPresentation.labelKey(for: .error("x")), "settings.sync.status.error")
    }

    func testToggleDisabledOnlyWhenUnavailable() {
        XCTAssertFalse(SyncStatusPresentation.isToggleEnabled(for: .unavailable))
        XCTAssertTrue(SyncStatusPresentation.isToggleEnabled(for: .off))
        XCTAssertTrue(SyncStatusPresentation.isToggleEnabled(for: .on))
    }

    func testFootnoteOnlyWhenUnavailable() {
        XCTAssertEqual(SyncStatusPresentation.footnoteKey(for: .unavailable), "settings.sync.unavailable_note")
        XCTAssertNil(SyncStatusPresentation.footnoteKey(for: .off))
        XCTAssertNil(SyncStatusPresentation.footnoteKey(for: .on))
    }

    func testAllStatusLabelKeysResolveInEnglishBundle() {
        // Guard against missing localized entries for the new keys.
        let statuses: [SyncStatus] = [.off, .unavailable, .on, .syncing, .idle, .error("e")]
        for status in statuses {
            let key = SyncStatusPresentation.labelKey(for: status)
            let resolved = L10n.string(key, locale: .en)
            XCTAssertNotEqual(resolved, key, "Missing English localization for \(key)")
        }
    }
}
