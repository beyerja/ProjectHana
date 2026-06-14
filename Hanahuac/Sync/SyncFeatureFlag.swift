import Foundation

/// The single source of truth for whether the CloudKit sync path is *compiled in*.
///
/// This is THE flag to flip once a paid Apple Developer account + iCloud container exist
/// (see `docs/icloud-sync.md`). It is intentionally a compile-time condition so the default
/// build never references entitlement-bound CloudKit APIs and therefore always builds and passes
/// CI under free signing.
///
/// To enable later: define `CLOUDKIT_SYNC` in the target's `SWIFT_ACTIVE_COMPILATION_CONDITIONS`
/// (via `project.yml` / xcconfig), add the iCloud entitlements, and regenerate the project.
enum SyncFeatureFlag {
    /// True only when the project is built with the `CLOUDKIT_SYNC` compilation condition.
    static var isCompiledIn: Bool {
        #if CLOUDKIT_SYNC
        return true
        #else
        return false
        #endif
    }

    /// The CloudKit container identifier that will back sync once enabled. Kept here (rather than
    /// scattered) so enabling sync is a single, discoverable change.
    static let containerIdentifier = "iCloud.com.hanahuac.app"
}
