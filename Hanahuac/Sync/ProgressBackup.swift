import Foundation

/// Non-destructive backup of the on-disk SwiftData progress store.
///
/// The app must never delete the user's progress without first copying it somewhere recoverable.
/// This helper mirrors the recipe-level safety net in `scripts/backup-progress.sh`: it snapshots the
/// `default.store` (and its `-wal` / `-shm` sidecars) into a timestamped directory under a shared
/// backups root, and caps how many snapshots are kept. Both the root and the retention cap match the
/// recipe so the two layers stay consistent.
enum ProgressBackup {
    /// Shared backups root: `~/Library/Application Support/Hanahuac-backups/`.
    /// Matches `BACKUP_ROOT` in `scripts/backup-progress.sh`.
    static var backupRoot: URL {
        URL.applicationSupportDirectory.appending(path: "Hanahuac-backups", directoryHint: .isDirectory)
    }

    /// Keep at most this many timestamped backup directories; prune the oldest beyond it.
    /// Matches `RETENTION` in `scripts/backup-progress.sh`.
    static let retention = 10

    /// SwiftData store sidecar suffixes (the base store has an empty suffix).
    static let storeSuffixes = ["", "-wal", "-shm"]

    /// Copy the store at `storeURL` (plus its `-wal`/`-shm` sidecars) into a fresh timestamped backup
    /// directory under ``backupRoot``, then prune to ``retention``.
    ///
    /// - Parameters:
    ///   - storeURL: the live store path (typically `applicationSupportDirectory/default.store`).
    ///   - reason: a short suffix appended to the timestamp (e.g. `"autorecover"`) so the cause of
    ///     the backup is visible on disk. Pass `nil` for a bare timestamp.
    ///   - root: the backups root directory; defaults to ``backupRoot``. Injectable for testing.
    ///   - fileManager: injectable for testing.
    /// - Returns: the backup directory URL if at least one file was copied, otherwise `nil`
    ///   (e.g. no store exists yet — a fresh install).
    @discardableResult
    static func backUpStore(
        at storeURL: URL,
        reason: String? = nil,
        root: URL? = nil,
        fileManager: FileManager = .default
    ) -> URL? {
        let backupsDir = root ?? backupRoot
        let stamp = timestamp()
        let dirName = reason.map { "\(stamp)-\($0)" } ?? stamp
        let dest = backupsDir.appending(path: dirName, directoryHint: .isDirectory)

        var copiedAny = false
        for suffix in storeSuffixes {
            let src = URL(fileURLWithPath: storeURL.path + suffix)
            guard fileManager.fileExists(atPath: src.path) else { continue }
            do {
                if !copiedAny {
                    try fileManager.createDirectory(at: dest, withIntermediateDirectories: true)
                }
                let target = dest.appending(path: src.lastPathComponent)
                try fileManager.copyItem(at: src, to: target)
                copiedAny = true
            } catch {
                // Best-effort: a failed copy of one sidecar must not block recovery of the rest.
                continue
            }
        }

        guard copiedAny else { return nil }
        prune(root: backupsDir, fileManager: fileManager)
        return dest
    }

    /// Remove the oldest backup directories so at most ``retention`` remain.
    /// - Parameter root: the backups root; defaults to ``backupRoot``.
    static func prune(root: URL? = nil, fileManager: FileManager = .default) {
        guard let entries = try? fileManager.contentsOfDirectory(
            at: root ?? backupRoot,
            includingPropertiesForKeys: nil
        ) else { return }
        // Timestamped names sort chronologically, so a lexical sort is a chronological sort.
        let dirs = entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        guard dirs.count > retention else { return }
        for dir in dirs.prefix(dirs.count - retention) {
            try? fileManager.removeItem(at: dir)
        }
    }

    /// UTC `yyyyMMdd'T'HHmmss'Z'` stamp — same format as the recipe's `date -u +%Y%m%dT%H%M%SZ`.
    static func timestamp(now: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.string(from: now)
    }
}
