import Foundation
import XCTest
@testable import Hanahuac

/// Verifies the non-destructive backup helper that `SyncCoordinator.makeModelContainer()` relies on
/// to ensure the user's progress is copied somewhere recoverable BEFORE any store deletion.
final class ProgressBackupTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(path: "ProgressBackupTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
        try super.tearDownWithError()
    }

    /// Writes a fake store + sidecars at `tempDir/default.store{,-wal,-shm}`. Returns the store URL.
    private func seedStore(contents: String = "store-bytes") throws -> URL {
        let storeURL = tempDir.appending(path: "default.store")
        for suffix in ProgressBackup.storeSuffixes {
            let url = URL(fileURLWithPath: storeURL.path + suffix)
            try Data("\(contents)\(suffix)".utf8).write(to: url)
        }
        return storeURL
    }

    private func backupsRoot() -> URL {
        tempDir.appending(path: "Hanahuac-backups", directoryHint: .isDirectory)
    }

    /// A backup copies the store + both sidecars into a fresh timestamped directory, and crucially
    /// leaves the ORIGINAL store untouched (non-destructive).
    func testBackUpCopiesStoreAndSidecarsWithoutDeletingOriginal() throws {
        let storeURL = try seedStore()
        let dest = ProgressBackup.backUpStore(
            at: storeURL,
            reason: "autorecover",
            root: backupsRoot()
        )
        let dest1 = try XCTUnwrap(dest, "expected a backup directory when a store exists")

        // Original still present — the helper must never delete on its own.
        for suffix in ProgressBackup.storeSuffixes {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: storeURL.path + suffix),
                "original \(suffix.isEmpty ? "store" : suffix) must survive backup"
            )
        }
        // All three files copied into the backup dir.
        for name in ["default.store", "default.store-wal", "default.store-shm"] {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: dest1.appending(path: name).path),
                "backup must contain \(name)"
            )
        }
        XCTAssertTrue(dest1.lastPathComponent.hasSuffix("-autorecover"))
    }

    /// No store on disk (fresh install) → nil, no backup directory created, no error.
    func testBackUpReturnsNilWhenNoStoreExists() {
        let storeURL = tempDir.appending(path: "default.store")
        let dest = ProgressBackup.backUpStore(at: storeURL, root: backupsRoot())
        XCTAssertNil(dest)
        XCTAssertFalse(FileManager.default.fileExists(atPath: backupsRoot().path))
    }

    /// Retention cap keeps only the newest `retention` backup directories.
    func testPruneKeepsOnlyMostRecentBackups() throws {
        let root = backupsRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        // Create more than the cap, with lexically-sortable (chronological) names.
        let total = ProgressBackup.retention + 5
        var names: [String] = []
        for i in 0 ..< total {
            let name = String(format: "20200101T0000%02dZ", i)
            names.append(name)
            try FileManager.default.createDirectory(
                at: root.appending(path: name, directoryHint: .isDirectory),
                withIntermediateDirectories: true
            )
        }

        ProgressBackup.prune(root: root)

        let remaining = try FileManager.default.contentsOfDirectory(atPath: root.path).sorted()
        XCTAssertEqual(remaining.count, ProgressBackup.retention)
        // The newest `retention` names are the ones kept.
        XCTAssertEqual(remaining, Array(names.suffix(ProgressBackup.retention)))
    }

    /// A backup that pushes the count over the cap triggers pruning down to the cap.
    func testBackUpPrunesOverCap() throws {
        let root = backupsRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        // Pre-fill exactly `retention` old dirs whose names sort BEFORE any real UTC timestamp.
        for i in 0 ..< ProgressBackup.retention {
            try FileManager.default.createDirectory(
                at: root.appending(path: String(format: "20000101T0000%02dZ", i), directoryHint: .isDirectory),
                withIntermediateDirectories: true
            )
        }
        let storeURL = try seedStore()
        _ = ProgressBackup.backUpStore(at: storeURL, root: root)

        let remaining = try FileManager.default.contentsOfDirectory(atPath: root.path)
        XCTAssertEqual(
            remaining.count,
            ProgressBackup.retention,
            "after a backup the dir count must be capped at the retention limit"
        )
    }
}
