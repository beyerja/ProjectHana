import Foundation
import SwiftData

/// One-time, idempotent migration that attributes pre-existing **global** progress to the language
/// that is active at upgrade time. Every other language starts empty.
///
/// Before per-language progress, all progress was stored with no language dimension:
/// - SwiftData rows (`ReviewCard`, `DailyProgressSnapshot`) — after the schema gained `language`,
///   legacy rows carry `language == ""`.
/// - Key-value progress — the streak (`streak_count` / `streak_lastReviewDate`) and the active set
///   (`activeSet.<category>`) under un-namespaced keys.
///
/// This migrator stamps the empty-language SwiftData rows with the active locale and copies the
/// legacy key-value data into the active language's namespaced keys. It is safe to call on every
/// launch: a persisted version flag short-circuits after the first successful run, and each step is
/// additionally guarded by presence checks (empty-language filter for rows; "namespaced key absent"
/// for key-value), so a re-run never duplicates, drops, or re-stamps already-migrated data. Fresh
/// installs (no legacy data) are unaffected — there is nothing to stamp or copy.
///
/// Run this at startup BEFORE the language-scoped stores seed, so seeding never creates
/// empty-language rows ahead of the stamp.
enum ProgressMigrator {
    /// Persisted "this migration has run" marker. Stored in `UserDefaults` (not synced) because it
    /// describes a per-device upgrade event, not user content.
    static let versionKey = "progress.perLanguageMigration.v1.done"

    /// Performs the migration for `activeLanguage` (an `AppLocale.rawValue`).
    ///
    /// - Parameters:
    ///   - context: the SwiftData context holding the progress rows.
    ///   - activeLanguage: the locale to attribute existing global progress to.
    ///   - defaults: the key-value store for the streak/active-set legacy data + version flag.
    static func migrateIfNeeded(
        context: ModelContext,
        activeLanguage: String,
        defaults: UserDefaults = .standard
    ) {
        guard !defaults.bool(forKey: versionKey) else { return }

        stampSwiftDataRows(context: context, language: activeLanguage)
        migrateStreakKeys(language: activeLanguage, defaults: defaults)
        migrateActiveSetKeys(language: activeLanguage, defaults: defaults)

        defaults.set(true, forKey: versionKey)
    }

    // MARK: - SwiftData rows

    /// Stamps every `ReviewCard` / `DailyProgressSnapshot` whose `language` is empty with
    /// `language`. Only empty-language rows are touched, so a second run is a no-op even if the
    /// version flag were cleared.
    private static func stampSwiftDataRows(context: ModelContext, language: String) {
        // Fetch all rows and filter empty-language ones in memory: a `#Predicate` on
        // `String.isEmpty` / `== ""` does not reliably translate to the SwiftData store query, so we
        // match in Swift to be robust.
        let cards = ((try? context.fetch(FetchDescriptor<ReviewCard>())) ?? [])
            .filter(\.language.isEmpty)
        for card in cards {
            card.language = language
        }

        let snapshots = ((try? context.fetch(FetchDescriptor<DailyProgressSnapshot>())) ?? [])
            .filter(\.language.isEmpty)
        for snapshot in snapshots {
            snapshot.language = language
        }

        if !cards.isEmpty || !snapshots.isEmpty {
            try? context.save()
        }
    }

    // MARK: - Key-value progress

    /// Copies the legacy streak count + last-review date into the active language's keys, only when
    /// the language-namespaced keys are absent (so a re-run, or a user who already has per-language
    /// data, is never overwritten). The legacy keys are then removed.
    private static func migrateStreakKeys(language: String, defaults: UserDefaults) {
        let namespacedCount = StreakTracker.streakKey(for: language)
        let namespacedDate = StreakTracker.lastReviewKey(for: language)

        let hasLegacyCount = defaults.object(forKey: StreakTracker.legacyStreakKey) != nil
        let alreadyMigrated = defaults.object(forKey: namespacedCount) != nil
        guard hasLegacyCount, !alreadyMigrated else { return }

        defaults.set(defaults.integer(forKey: StreakTracker.legacyStreakKey), forKey: namespacedCount)
        if let legacyDate = defaults.object(forKey: StreakTracker.legacyLastReviewKey) as? Date {
            defaults.set(legacyDate, forKey: namespacedDate)
        }

        defaults.removeObject(forKey: StreakTracker.legacyStreakKey)
        defaults.removeObject(forKey: StreakTracker.legacyLastReviewKey)
    }

    /// Copies each category's legacy active set into the active language's namespaced key, only when
    /// the namespaced key is absent. The legacy keys are then removed.
    private static func migrateActiveSetKeys(language: String, defaults: UserDefaults) {
        for category in CardCategory.allCases {
            let legacyKey = legacyActiveSetKey(for: category)
            guard let legacyValue = defaults.stringArray(forKey: legacyKey) else { continue }
            let namespacedKey = activeSetKey(language: language, category: category)
            if defaults.stringArray(forKey: namespacedKey) == nil {
                defaults.set(legacyValue, forKey: namespacedKey)
            }
            defaults.removeObject(forKey: legacyKey)
        }
    }
}
