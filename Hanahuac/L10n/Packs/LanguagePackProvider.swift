import Foundation

/// The availability state of a language pack, so call sites never branch on "bundled vs ODR vs CDN".
///
/// Every consumer asks the provider for the resolved string source and geo-name data and reacts to
/// this single state, rather than knowing how the pack is delivered. The bundled provider always
/// reports ``available`` for the base languages; the future ODR/CDN providers will surface
/// ``notDownloaded`` / ``downloading`` / ``failed`` without changing any call site.
enum LanguagePackState: Equatable {
    /// The pack's resources are present and ready to use.
    case available
    /// The pack is not present yet and must be downloaded (ODR/CDN variants).
    case notDownloaded
    /// A download is in progress.
    case downloading
    /// A download or verification attempt failed; the app falls back to bundled names.
    case failed
}

/// The seam the whole downloadable-language-packs feature pivots on.
///
/// Given a language (an ``AppLocale``), a provider exposes everything a call site needs to render
/// that language without knowing where the pack came from:
/// - ``stringBundle(for:)`` — the resolved `Bundle` to read UI strings from (mirrors
///   ``L10n/bundle(for:)``), so `L10n`-style lookups can route through a provider in later stories.
/// - ``geoNameData(for:)`` — the validated ``GeoNamePackData`` for that language, or `nil` when the
///   language has no pack data (callers then walk the locale's `fallbackChain`).
/// - ``state(for:)`` — the pack's availability, so the picker/UI never special-cases delivery.
///
/// ## Pluggability for the future signed-CDN provider
/// This protocol is deliberately delivery-agnostic. A future `SignedCDNLanguagePackProvider` will
/// conform by:
/// 1. Downloading a pack archive over the network, then verifying it with **Ed25519** signatures
///    over a **SHA-256** digest against a **pinned public key** baked into the app.
/// 2. Extracting the archive with **zip-slip-safe** path handling (rejecting any entry that escapes
///    the destination directory).
/// 3. Decoding the extracted geo JSON through ``GeoNamePackLoader`` (which schema-validates and never
///    `fatalError`s), and exposing the `.lproj` as the ``stringBundle(for:)``.
/// 4. Reporting ``LanguagePackState`` transitions (`notDownloaded` → `downloading` → `available` or
///    `failed`) so call sites are unchanged.
/// None of that network/crypto/extraction code exists in this story — only the seam does. The
/// bundled provider below is the first, always-available conformer.
protocol LanguagePackProvider {
    /// The resolved `Bundle` to read this locale's UI strings from. Returns `.main` (or the closest
    /// fallback) when no dedicated bundle exists, so callers always get a usable bundle.
    func stringBundle(for locale: AppLocale) -> Bundle

    /// The validated geo-name pack data for this locale, or `nil` when this locale has no pack data
    /// (callers resolve through the locale's `fallbackChain` in that case).
    func geoNameData(for locale: AppLocale) -> GeoNamePackData?

    /// The availability state of this locale's pack.
    func state(for locale: AppLocale) -> LanguagePackState
}
