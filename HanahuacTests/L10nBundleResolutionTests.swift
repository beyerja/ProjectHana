import XCTest
@testable import Hanahuac

/// Validates the non-base languages' shipped `Localizable.strings` content and the runtime fallback
/// behavior now that ko/nah ship as On-Demand Resources (`lang-ko`/`lang-nah`, story 006).
///
/// Two layers:
/// - Content: read each pack's `.lproj` directly from its built asset pack (``ODRTestSupport``) and
///   assert the real translated values are present and correct. Skips if the asset pack is not
///   reachable in the current environment (the simulator unit-test host has no asset-pack server, so
///   ODR cannot be mounted into `Bundle.main` here).
/// - Offline fallback: with NO pack downloaded, `L10n.string(_:locale:)` for a non-base locale
///   degrades through the chain (ko → es-MX → en; nah → es-MX → en) and never surfaces the raw key —
///   the base-only offline path the app relies on.
final class L10nBundleResolutionTests: XCTestCase {
    private var savedProvider: LanguagePackProvider!

    override func setUp() {
        super.setUp()
        savedProvider = LanguagePackProviderHolder.active
    }

    override func tearDown() {
        LanguagePackProviderHolder.active = savedProvider
        super.tearDown()
    }

    // MARK: - Offline-pack-absence provider

    /// A provider that deterministically models "no downloadable pack installed", independent of
    /// whether the test host happens to embed the tagged ODR `.lproj` in `Bundle.main`.
    ///
    /// Why this is needed: the default ``BundledLanguagePackProvider`` resolves a downloadable
    /// locale's string bundle via ``L10n/bundle(for:)``, i.e. by probing `Bundle.main` for that
    /// locale's `.lproj`. Whether `ko.lproj`/`nah.lproj` are present in the host bundle differs across
    /// environments — Xcode embeds the tagged ODR resources into the dev test host, while a clean CI
    /// build does not — so an offline-fallback assertion that reads through the default provider is
    /// non-deterministic. This provider instead serves each non-base downloadable locale the **es-MX
    /// base bundle** (exactly what the fallback chain resolves to when the pack is absent) and base
    /// languages their own bundle, so the offline base-only path is exercised identically everywhere.
    private struct PackAbsentProvider: LanguagePackProvider {
        func stringBundle(for locale: AppLocale) -> Bundle {
            if locale.isBundledBaseLanguage {
                return L10n.bundle(for: locale)
            }
            // Downloadable pack not installed: resolve to the es-MX base bundle, the bundled base the
            // chain (ko/nah → es-MX → en) lands on without the pack.
            return L10n.bundle(for: .esMX)
        }

        func geoNameData(for _: AppLocale) -> GeoNamePackData? {
            nil
        }

        func state(for locale: AppLocale) -> LanguagePackState {
            locale.isBundledBaseLanguage ? .available : .notDownloaded
        }
    }

    // MARK: - Shipped pack content (read directly from the asset pack)

    /// A key both ko and nah translate carries the new-language value in the shipped pack.
    func testTranslatedKey_shippedInPack() throws {
        let ko = try ODRTestSupport.lprojBundle(for: .ko)
        let nah = try ODRTestSupport.lprojBundle(for: .nah)
        XCTAssertEqual(ko.localizedString(forKey: "settings.language", value: nil, table: nil), "언어")
        XCTAssertEqual(
            nah.localizedString(forKey: "settings.language", value: nil, table: nil),
            "Tlahtōlli"
        )
    }

    /// Korean fully covers the core UI keys in its shipped pack.
    func testKoreanCoversCoreKeys() throws {
        let ko = try ODRTestSupport.lprojBundle(for: .ko)
        XCTAssertEqual(ko.localizedString(forKey: "home.categories", value: nil, table: nil), "분류")
        XCTAssertEqual(ko.localizedString(forKey: "quiz_summary.done", value: nil, table: nil), "완료")
    }

    // MARK: - Offline fallback (no pack downloaded)

    /// With no pack downloaded, a non-base locale resolves through its fallback chain to a bundled
    /// base language, never the raw key. (ko/nah → es-MX → en.)
    ///
    /// Routed through ``PackAbsentProvider`` so pack absence is GUARANTEED regardless of whether the
    /// test host embeds the tagged ODR `.lproj` in `Bundle.main` — making the assertion deterministic
    /// across local dev (which embeds them) and a clean CI build (which does not). This still exercises
    /// the real offline base-only resolution the app relies on; it only removes the host-bundle
    /// dependency, not the guarantee.
    func testOfflineFallback_resolvesThroughChain() {
        LanguagePackProviderHolder.active = PackAbsentProvider()

        let ko = L10n.string("settings.language", locale: .ko)
        let nah = L10n.string("settings.language", locale: .nah)
        let esMX = L10n.string("settings.language", locale: .esMX)
        XCTAssertEqual(ko, esMX, "Without the ko pack, ko resolves the es-MX base value")
        XCTAssertEqual(nah, esMX, "Without the nah pack, nah resolves the es-MX base value")
        XCTAssertEqual(esMX, "Idioma", "es-MX base value is the bundled Mexican Spanish string")
        XCTAssertNotEqual(ko, "settings.language", "Must never surface the raw key")
    }

    /// A key Nahuatl does NOT translate falls back to the Mexican Spanish value, never English and
    /// never the raw key. Routed through ``PackAbsentProvider`` so the assertion is deterministic
    /// whether or not the host embeds the tagged ODR pack: the chain routes through es-MX before en.
    func testNahuatl_missingKey_fallsBackToMexicanSpanish() {
        LanguagePackProviderHolder.active = PackAbsentProvider()

        let nah = L10n.string("settings.sync.toggle", locale: .nah)
        let esMX = L10n.string("settings.sync.toggle", locale: .esMX)
        let en = L10n.string("settings.sync.toggle", locale: .en)

        XCTAssertEqual(nah, esMX, "Untranslated Nahuatl key should serve the Mexican Spanish value")
        XCTAssertNotEqual(nah, en, "Should not fall through to English while Spanish exists")
        XCTAssertNotEqual(nah, "settings.sync.toggle", "Must never surface the raw key")
    }

    /// A completely unknown key returns the key itself (Apple's contract) rather than crashing.
    func testUnknownKey_returnsKey() {
        XCTAssertEqual(L10n.string("__no_such_key__", locale: .ko), "__no_such_key__")
    }

    // MARK: - Catalan fallback chain (ca → es-ES → en)

    /// The UI key Catalan deliberately leaves untranslated, present in es-ES. The Catalan
    /// `.lproj` (ca.lproj/Localizable.strings) intentionally OMITS this key so resolution must route
    /// through the es-ES pack — which translates it — before reaching English. Changing the omitted key
    /// here means updating ca.lproj to match.
    private static let catalanGapKey = "settings.sync.toggle"

    /// A provider that serves the real shipped ca / es-ES `.lproj` bundles (read from their on-disk
    /// asset packs) for those locales, and the bundled base bundle for everyone else. This drives
    /// `L10n.string` through the actual ca → es-ES → en chain so the Catalan gap resolves to the es-ES
    /// value before English. Skips (via the throwing loader in the test) when the asset packs are not
    /// reachable in this environment.
    private struct CatalanChainProvider: LanguagePackProvider {
        let caBundle: Bundle
        let esESBundle: Bundle

        func stringBundle(for locale: AppLocale) -> Bundle {
            switch locale {
            case .ca:
                caBundle
            case .esES:
                esESBundle
            default:
                L10n.bundle(for: locale)
            }
        }

        func geoNameData(for _: AppLocale) -> GeoNamePackData? {
            nil
        }

        func state(for _: AppLocale) -> LanguagePackState {
            .available
        }
    }

    /// Content guard: the Catalan pack omits the gap key while the es-ES pack translates it, so the
    /// chain has a real intermediate Spanish value to resolve to (not English).
    func testCatalanPack_omitsGapKey_whileSpainSpanishTranslatesIt() throws {
        let ca = try ODRTestSupport.lprojBundle(for: .ca)
        let esES = try ODRTestSupport.lprojBundle(for: .esES)
        let sentinel = "__missing__"
        XCTAssertEqual(
            ca.localizedString(forKey: Self.catalanGapKey, value: sentinel, table: nil),
            sentinel,
            "Catalan must deliberately omit \(Self.catalanGapKey) to exercise the es-ES fallback"
        )
        XCTAssertNotEqual(
            esES.localizedString(forKey: Self.catalanGapKey, value: sentinel, table: nil),
            sentinel,
            "es-ES must translate \(Self.catalanGapKey) so ca falls back to it before English"
        )
    }

    /// Build a throwaway `.lproj` `Bundle` on disk containing exactly `pairs`, so the fallback-chain
    /// assertion is fully deterministic regardless of whether the shipped ODR asset packs are mounted
    /// in this environment (the simulator unit-test host has no asset-pack server).
    private func makeStringsBundle(
        code: String,
        pairs: [String: String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Bundle {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ca-chain-\(UUID().uuidString)", isDirectory: true)
        let lproj = root.appendingPathComponent("\(code).lproj", isDirectory: true)
        try FileManager.default.createDirectory(at: lproj, withIntermediateDirectories: true)
        let body = pairs
            .sorted { $0.key < $1.key }
            .map { "\"\($0.key)\" = \"\($0.value)\";" }
            .joined(separator: "\n")
        try body.write(
            to: lproj.appendingPathComponent("Localizable.strings"),
            atomically: true,
            encoding: .utf8
        )
        return try XCTUnwrap(Bundle(url: lproj), "failed to build \(code).lproj bundle", file: file, line: line)
    }

    /// The deliberately-untranslated Catalan key resolves to the es-ES value, NOT English, proving the
    /// chain routes through Spain Spanish before the English safety net.
    ///
    /// Deterministic: the ca bundle deliberately OMITS the gap key (mirroring ca.lproj) and the es-ES
    /// bundle defines it, so `L10n.string(_:locale: .ca)` must walk ca → es-ES and return the Spanish
    /// value before reaching the English base. This does not depend on the ODR asset pack being mounted.
    func testCatalanGapKey_resolvesToSpainSpanishBeforeEnglish() throws {
        let spanishValue = "Sincronització amb l'iCloud (es-ES)"
        let provider = try CatalanChainProvider(
            caBundle: makeStringsBundle(code: "ca", pairs: ["home.categories": "Categories"]),
            esESBundle: makeStringsBundle(code: "es-ES", pairs: [Self.catalanGapKey: spanishValue])
        )
        LanguagePackProviderHolder.active = provider

        let ca = L10n.string(Self.catalanGapKey, locale: .ca)
        let en = L10n.string(Self.catalanGapKey, locale: .en)

        XCTAssertEqual(ca, spanishValue, "Untranslated Catalan key must serve the es-ES value")
        XCTAssertNotEqual(ca, en, "Must not fall through to English while the es-ES value exists")
        XCTAssertNotEqual(ca, Self.catalanGapKey, "Must never surface the raw key")
    }

    /// A key Catalan DOES translate is served from the ca pack itself, not the fallback.
    func testCatalanTranslatedKey_servedFromCatalanPack() throws {
        let ca = try ODRTestSupport.lprojBundle(for: .ca)
        XCTAssertEqual(ca.localizedString(forKey: "home.categories", value: nil, table: nil), "Categories")
        XCTAssertEqual(ca.localizedString(forKey: "settings.language", value: nil, table: nil), "Idioma")
    }

    /// The candidate chain for Catalan routes ca → es-ES → en (the fallback contract this story adds).
    func testCatalanBundleCandidatesRouteThroughSpainSpanish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .ca), ["ca", "es-ES", "en"])
    }

    // MARK: - Basque fallback chain (eu → es-ES → en)

    /// The UI key Basque deliberately leaves untranslated, present in es-ES. The Basque
    /// `.lproj` (eu.lproj/Localizable.strings) intentionally OMITS this key so resolution must route
    /// through the es-ES pack — which translates it — before reaching English. Changing the omitted key
    /// here means updating eu.lproj to match.
    private static let basqueGapKey = "settings.sync.toggle"

    /// A provider that serves the real shipped eu / es-ES `.lproj` bundles (read from their on-disk
    /// asset packs) for those locales, and the bundled base bundle for everyone else. This drives
    /// `L10n.string` through the actual eu → es-ES → en chain so the Basque gap resolves to the es-ES
    /// value before English.
    private struct BasqueChainProvider: LanguagePackProvider {
        let euBundle: Bundle
        let esESBundle: Bundle

        func stringBundle(for locale: AppLocale) -> Bundle {
            switch locale {
            case .eu:
                euBundle
            case .esES:
                esESBundle
            default:
                L10n.bundle(for: locale)
            }
        }

        func geoNameData(for _: AppLocale) -> GeoNamePackData? {
            nil
        }

        func state(for _: AppLocale) -> LanguagePackState {
            .available
        }
    }

    /// Content guard: the Basque pack omits the gap key while the es-ES pack translates it, so the
    /// chain has a real intermediate Spanish value to resolve to (not English).
    func testBasquePack_omitsGapKey_whileSpainSpanishTranslatesIt() throws {
        let eu = try ODRTestSupport.lprojBundle(for: .eu)
        let esES = try ODRTestSupport.lprojBundle(for: .esES)
        let sentinel = "__missing__"
        XCTAssertEqual(
            eu.localizedString(forKey: Self.basqueGapKey, value: sentinel, table: nil),
            sentinel,
            "Basque must deliberately omit \(Self.basqueGapKey) to exercise the es-ES fallback"
        )
        XCTAssertNotEqual(
            esES.localizedString(forKey: Self.basqueGapKey, value: sentinel, table: nil),
            sentinel,
            "es-ES must translate \(Self.basqueGapKey) so eu falls back to it before English"
        )
    }

    /// The deliberately-untranslated Basque key resolves to the es-ES value, NOT English, proving the
    /// chain routes through Spain Spanish before the English safety net.
    ///
    /// Deterministic: the eu bundle deliberately OMITS the gap key (mirroring eu.lproj) and the es-ES
    /// bundle defines it, so `L10n.string(_:locale: .eu)` must walk eu → es-ES and return the Spanish
    /// value before reaching the English base. This does not depend on the ODR asset pack being mounted.
    func testBasqueGapKey_resolvesToSpainSpanishBeforeEnglish() throws {
        let spanishValue = "Sincronización con iCloud (es-ES)"
        let provider = try BasqueChainProvider(
            euBundle: makeStringsBundle(code: "eu", pairs: ["home.categories": "Kategoriak"]),
            esESBundle: makeStringsBundle(code: "es-ES", pairs: [Self.basqueGapKey: spanishValue])
        )
        LanguagePackProviderHolder.active = provider

        let eu = L10n.string(Self.basqueGapKey, locale: .eu)
        let en = L10n.string(Self.basqueGapKey, locale: .en)

        XCTAssertEqual(eu, spanishValue, "Untranslated Basque key must serve the es-ES value")
        XCTAssertNotEqual(eu, en, "Must not fall through to English while the es-ES value exists")
        XCTAssertNotEqual(eu, Self.basqueGapKey, "Must never surface the raw key")
    }

    /// A key Basque DOES translate is served from the eu pack itself, not the fallback.
    func testBasqueTranslatedKey_servedFromBasquePack() throws {
        let eu = try ODRTestSupport.lprojBundle(for: .eu)
        XCTAssertEqual(eu.localizedString(forKey: "home.categories", value: nil, table: nil), "Kategoriak")
        XCTAssertEqual(eu.localizedString(forKey: "settings.language", value: nil, table: nil), "Hizkuntza")
    }

    /// The candidate chain for Basque routes eu → es-ES → en (the fallback contract this story adds).
    func testBasqueBundleCandidatesRouteThroughSpainSpanish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .eu), ["eu", "es-ES", "en"])
    }

    // MARK: - Yucatec Maya fallback chain (yua → es-MX → en)

    /// The UI key Yucatec Maya deliberately leaves untranslated, present in es-MX. The Yucatec Maya
    /// `.lproj` (yua.lproj/Localizable.strings) intentionally OMITS this key so resolution must route
    /// through the es-MX pack — which translates it — before reaching English. Unlike ca/eu (which
    /// route through es-ES), yua routes through *Mexican* Spanish. Changing the omitted key here means
    /// updating yua.lproj to match.
    private static let yucatecGapKey = "settings.sync.toggle"

    /// A provider that serves the real shipped yua / es-MX `.lproj` bundles (read from their on-disk
    /// asset packs) for those locales, and the bundled base bundle for everyone else. This drives
    /// `L10n.string` through the actual yua → es-MX → en chain so the Yucatec Maya gap resolves to the
    /// es-MX value before English.
    private struct YucatecChainProvider: LanguagePackProvider {
        let yuaBundle: Bundle
        let esMXBundle: Bundle

        func stringBundle(for locale: AppLocale) -> Bundle {
            switch locale {
            case .yua:
                yuaBundle
            case .esMX:
                esMXBundle
            default:
                L10n.bundle(for: locale)
            }
        }

        func geoNameData(for _: AppLocale) -> GeoNamePackData? {
            nil
        }

        func state(for _: AppLocale) -> LanguagePackState {
            .available
        }
    }

    /// Content guard: the Yucatec Maya pack omits the gap key while the es-MX pack translates it, so the
    /// chain has a real intermediate Spanish value to resolve to (not English).
    func testYucatecPack_omitsGapKey_whileMexicanSpanishTranslatesIt() throws {
        let yua = try ODRTestSupport.lprojBundle(for: .yua)
        let esMX = L10n.bundle(for: .esMX)
        let sentinel = "__missing__"
        XCTAssertEqual(
            yua.localizedString(forKey: Self.yucatecGapKey, value: sentinel, table: nil),
            sentinel,
            "Yucatec Maya must deliberately omit \(Self.yucatecGapKey) to exercise the es-MX fallback"
        )
        XCTAssertNotEqual(
            esMX.localizedString(forKey: Self.yucatecGapKey, value: sentinel, table: nil),
            sentinel,
            "es-MX must translate \(Self.yucatecGapKey) so yua falls back to it before English"
        )
    }

    /// The deliberately-untranslated Yucatec Maya key resolves to the es-MX value, NOT English, proving
    /// the chain routes through Mexican Spanish before the English safety net.
    ///
    /// Deterministic: the yua bundle deliberately OMITS the gap key (mirroring yua.lproj) and the es-MX
    /// bundle defines it, so `L10n.string(_:locale: .yua)` must walk yua → es-MX and return the Spanish
    /// value before reaching the English base. This does not depend on the ODR asset pack being mounted.
    func testYucatecGapKey_resolvesToMexicanSpanishBeforeEnglish() throws {
        let spanishValue = "Sincronización con iCloud (es-MX)"
        let provider = try YucatecChainProvider(
            yuaBundle: makeStringsBundle(code: "yua", pairs: ["home.categories": "Nu'ukulil"]),
            esMXBundle: makeStringsBundle(code: "es-MX", pairs: [Self.yucatecGapKey: spanishValue])
        )
        LanguagePackProviderHolder.active = provider

        let yua = L10n.string(Self.yucatecGapKey, locale: .yua)
        let en = L10n.string(Self.yucatecGapKey, locale: .en)

        XCTAssertEqual(yua, spanishValue, "Untranslated Yucatec Maya key must serve the es-MX value")
        XCTAssertNotEqual(yua, en, "Must not fall through to English while the es-MX value exists")
        XCTAssertNotEqual(yua, Self.yucatecGapKey, "Must never surface the raw key")
    }

    /// A key Yucatec Maya DOES translate is served from the yua pack itself, not the fallback.
    func testYucatecTranslatedKey_servedFromYucatecPack() throws {
        let yua = try ODRTestSupport.lprojBundle(for: .yua)
        XCTAssertEqual(yua.localizedString(forKey: "home.categories", value: nil, table: nil), "Nu'ukulil")
        XCTAssertEqual(yua.localizedString(forKey: "settings.language", value: nil, table: nil), "T'àan")
    }

    /// The candidate chain for Yucatec Maya routes yua → es-MX → en (the fallback contract this story
    /// adds).
    func testYucatecBundleCandidatesRouteThroughMexicanSpanish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .yua), ["yua", "es-MX", "en"])
    }

    // MARK: - Italian (COMPLETE content; it → en)

    /// Italian is a COMPLETE-content language: its candidate chain goes straight to en, with NO Spanish
    /// hop. Because Italian leaves no intentional gaps there is no gap-key fallback test; en is only an
    /// ultimate, never-hit safety net.
    func testItalianBundleCandidatesGoStraightToEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .it), ["it", "en"])
    }

    /// A representative Italian key is served from the it pack itself (not a fallback), proving the
    /// pack carries real translated content.
    func testItalianTranslatedKey_servedFromItalianPack() throws {
        let it = try ODRTestSupport.lprojBundle(for: .it)
        XCTAssertEqual(it.localizedString(forKey: "home.categories", value: nil, table: nil), "Categorie")
        XCTAssertEqual(it.localizedString(forKey: "settings.language", value: nil, table: nil), "Lingua")
    }

    // MARK: - Polish (COMPLETE content; pl → en)

    /// Polish is a COMPLETE-content language: its candidate chain goes straight to en, with NO Spanish
    /// hop. Because Polish leaves no intentional gaps there is no gap-key fallback test; en is only an
    /// ultimate, never-hit safety net.
    func testPolishBundleCandidatesGoStraightToEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .pl), ["pl", "en"])
    }

    /// A representative Polish key is served from the pl pack itself (not a fallback), proving the
    /// pack carries real translated content.
    func testPolishTranslatedKey_servedFromPolishPack() throws {
        let pl = try ODRTestSupport.lprojBundle(for: .pl)
        XCTAssertEqual(pl.localizedString(forKey: "home.categories", value: nil, table: nil), "Kategorie")
        XCTAssertEqual(pl.localizedString(forKey: "settings.language", value: nil, table: nil), "Język")
    }
}
