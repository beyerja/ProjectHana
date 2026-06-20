import Foundation
import SwiftData

/// Versioned SwiftData schema for the app's persistent models.
///
/// Wrapping the models in a `VersionedSchema` + `SchemaMigrationPlan` is what lets a new app build
/// *open an existing on-disk store* across schema changes instead of throwing — which is exactly the
/// failure that used to trigger the destructive wipe in `SyncCoordinator.makeModelContainer()` and
/// silently erase the user's progress on upgrade.
///
/// `SchemaV3` is the current head schema; it adds the defaulted `quizMode: String` column to both
/// progress models so progress can be tracked independently per quiz mode (an orthogonal second
/// dimension to the `language` column `SchemaV2` added). Because the live `@Model` types ARE the V3
/// shape, the plan intentionally lists a SINGLE version (`SchemaV3`) with no explicit stages:
///
/// - An additive change with a model-level default (`quizMode == ""`, like `language == ""` before
///   it) is a SwiftData **lightweight** migration that the framework performs automatically when
///   opening an older (column-less) store against this schema — existing rows simply gain the
///   defaulted column, preserving all progress.
/// - Listing two `VersionedSchema`s that both point at the *same* current `@Model` types and joining
///   them with `MigrationStage.lightweight` instead makes SwiftData abort at container creation with
///   "retrieve an NSManagedObjectModel version checksum while the model is still editable", because
///   the two versions are indistinguishable. A `VersionedSchema` can only correctly represent a
///   *past* shape via frozen, duplicated model types — unnecessary for a purely additive default.
///   (A stale local store masks this abort; it only surfaces in CI / after `simctl erase`.)
///
/// The one-time `ProgressMigrator` (run at startup) then stamps the freshly-added empty `quizMode`
/// values with `mapQuiz` (all legacy progress was effectively the Map Tab Quiz), just as it stamps
/// empty `language` with the active locale. Genuinely incompatible stores still fall through to
/// `SyncCoordinator.recoverContainer` (non-destructive backup first).
///
/// For a future NON-additive change, introduce a frozen `SchemaV4` describing the new shape plus a
/// real `MigrationStage` (custom or lightweight) between distinct frozen versions.
enum SchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(3, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [ReviewCard.self, DailyProgressSnapshot.self]
    }
}

/// Migration plan for the app's schema. Lists only the current head schema (`SchemaV3`); additive
/// column adds are handled by SwiftData's automatic lightweight migration (see ``SchemaV3`` docs).
enum HanahuacMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
