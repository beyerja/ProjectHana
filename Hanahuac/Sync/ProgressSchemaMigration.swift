import Foundation
import SwiftData

/// Versioned schemas + migration plan for the progress models (`ReviewCard`,
/// `DailyProgressSnapshot`).
///
/// Per-language progress adds a defaulted `language: String` column to both models. Because every
/// new attribute carries a model-level default, the V1 → V2 step is a SwiftData **lightweight**
/// migration: the on-disk store is upgraded in place (rows gain `language == ""`) rather than wiped.
/// `SyncCoordinator.makeModelContainer()` passes this plan so the upgrade preserves existing
/// progress; its catch-all fallback still wipes the store only for genuinely incompatible schemas.
///
/// The app-level "stamp legacy rows with the active locale" step is intentionally NOT here — that is
/// a one-time, business-logic migration that depends on the active `AppLocale` at upgrade time and
/// runs at startup (see the migration story). This plan only handles the schema shape.
enum ProgressMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ProgressSchemaV1.self, ProgressSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    /// Lightweight: adding a defaulted column needs no custom willMigrate/didMigrate work.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: ProgressSchemaV1.self,
        toVersion: ProgressSchemaV2.self
    )
}

/// V1 — the pre-per-language schema. `models` lists the current `@Model` types; SwiftData compares
/// the persisted store's shape against `versionIdentifier` to decide whether a migration is needed.
/// We keep the live `@Model` types (which now carry `language`) referenced from V2; V1 exists purely
/// as the prior version marker so the lightweight stage has a "from" to upgrade.
enum ProgressSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [ReviewCard.self, DailyProgressSnapshot.self]
    }
}

/// V2 — adds the defaulted `language` column to both progress models.
enum ProgressSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [ReviewCard.self, DailyProgressSnapshot.self]
    }
}
