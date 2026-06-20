import Foundation
import SwiftData

/// Versioned SwiftData schema for the app's persistent models.
///
/// Wrapping the models in a `VersionedSchema` + `SchemaMigrationPlan` is what lets a new app build
/// *open an existing on-disk store* across schema changes instead of throwing — which is exactly the
/// failure that used to trigger the destructive wipe in `SyncCoordinator.makeModelContainer()` and
/// silently erase the user's progress on upgrade.
///
/// When the models change in a backwards-compatible (additive/lightweight) way, bump to a new
/// `VersionedSchema` (e.g. `SchemaV2`), add it to ``HanahuacMigrationPlan/schemas``, and append a
/// `.lightweight` `MigrationStage` from the previous version. SwiftData then performs the migration
/// in place, preserving all existing rows.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [ReviewCard.self, DailyProgressSnapshot.self]
    }
}

/// V2 — adds the defaulted `language: String` column to both progress models so progress can be
/// tracked independently per language. Every new attribute carries a model-level default, so the
/// V1 → V2 step is a lightweight (in-place) migration: existing rows gain `language == ""`, which the
/// one-time `ProgressMigrator` then stamps with the active locale at startup.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [ReviewCard.self, DailyProgressSnapshot.self]
    }
}

/// Migration plan across the app's schema versions. V1 is the initial shipped schema; future
/// versions append `.lightweight` (or custom) stages here.
enum HanahuacMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    /// Lightweight: adding a defaulted column needs no custom willMigrate/didMigrate work.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
