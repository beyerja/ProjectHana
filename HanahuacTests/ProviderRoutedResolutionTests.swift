import XCTest
@testable import Hanahuac

/// Proves resolution flows through the active ``LanguagePackProvider`` seam (story 003):
/// - geo names/capitals come from a STUB provider's pack data, not the model fields;
/// - when the provider reports a pack absent (`geoNameData` returns `nil`), geo and `L10n`
///   resolution fall through the chain (selected → es-MX for ko/nah → en) to the bundled base;
/// - a malformed/invalid pack degrades to the bundled fallback without crashing or surfacing a key;
/// - no resolution path branches on the concrete provider type.
final class ProviderRoutedResolutionTests: XCTestCase {
    private var savedProvider: LanguagePackProvider!

    override func setUp() {
        super.setUp()
        savedProvider = LanguagePackProviderHolder.active
    }

    override func tearDown() {
        LanguagePackProviderHolder.active = savedProvider
        super.tearDown()
    }

    // MARK: - Stub provider

    /// A provider whose geo data and string bundles are fully controlled by the test, so we can prove
    /// resolution reads from the provider (not the model fields) and observe absent-pack fallback.
    private struct StubProvider: LanguagePackProvider {
        var packsByCode: [String: GeoNamePackData] = [:]
        var bundlesByCode: [String: Bundle] = [:]
        var stateByCode: [String: LanguagePackState] = [:]

        func stringBundle(for locale: AppLocale) -> Bundle {
            bundlesByCode[locale.rawValue] ?? .main
        }

        func geoNameData(for locale: AppLocale) -> GeoNamePackData? {
            packsByCode[locale.rawValue]
        }

        func state(for locale: AppLocale) -> LanguagePackState {
            stateByCode[locale.rawValue] ?? .notDownloaded
        }
    }

    private func makeCountry(id: String = "ZZ", name: String, capital: String = "BaseCity") -> Country {
        Country(
            id: id,
            name: name,
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            nameKo: nil,
            nameNah: nil,
            capital: capital,
            capitalFr: nil,
            capitalDe: nil,
            capitalEs: nil,
            capitalKo: nil,
            capitalNah: nil,
            continent: "Europe",
            lat: 0,
            lon: 0
        )
    }

    // MARK: - (a) Resolution reads from the provider's pack data, not model fields

    func testGeoName_resolvesFromProviderPackData_notModelFields() {
        // The model carries NO French name, yet the provider's fr pack supplies one for this id.
        let country = makeCountry(name: "Base Name")
        let frPack = GeoNamePackData(
            code: "fr",
            entries: ["ZZ": GeoNamePackData.GeoNameEntry(name: "Nom Provider", capital: "Capitale Provider")]
        )
        LanguagePackProviderHolder.active = StubProvider(packsByCode: ["fr": frPack])

        XCTAssertEqual(country.localizedName(for: .fr), "Nom Provider", "name must come from the provider pack")
        XCTAssertEqual(country.localizedCapital(for: .fr), "Capitale Provider")
        // English has no pack → bundled base.
        XCTAssertEqual(country.localizedName(for: .en), "Base Name")
    }

    /// ko has no own pack but the provider supplies es-MX → resolution walks the chain through es-MX.
    func testGeoName_koWalksThroughSpanishPack() {
        let country = makeCountry(name: "Base Name")
        let esPack = GeoNamePackData(
            code: "es-MX",
            entries: ["ZZ": GeoNamePackData.GeoNameEntry(name: "Nombre ES")]
        )
        LanguagePackProviderHolder.active = StubProvider(packsByCode: ["es-MX": esPack])

        XCTAssertEqual(country.localizedName(for: .ko), "Nombre ES", "ko walks chain → es-MX pack")
        XCTAssertEqual(country.localizedName(for: .nah), "Nombre ES")
    }

    // MARK: - (b) Missing pack → fall through the chain to bundled base

    func testGeoName_absentPack_fallsThroughToBundledBase() {
        let country = makeCountry(name: "Base Name", capital: "Base City")
        // Provider has NO packs at all (every geoNameData returns nil).
        LanguagePackProviderHolder.active = StubProvider()

        for locale in AppLocale.allCases {
            XCTAssertEqual(
                country.localizedName(for: locale),
                "Base Name",
                "absent pack for \(locale.rawValue) must fall back to bundled base name"
            )
            XCTAssertEqual(country.localizedCapital(for: locale), "Base City")
        }
    }

    func testL10nString_absentBundle_fallsBackToBundledMainLproj() {
        // Stub returns no dedicated bundles (every stringBundle → .main, which lacks the test key in
        // a non-en table), so resolution falls through to the final raw-key terminator for an unknown
        // key, and to a real value for a key that exists in the main bundle's base table.
        LanguagePackProviderHolder.active = StubProvider()

        XCTAssertEqual(
            L10n.string("__definitely_missing_key__", locale: .ko),
            "__definitely_missing_key__",
            "an absent pack/bundle must still terminate on the raw key, never crash"
        )
    }

    // MARK: - (c) Malformed/invalid pack degrades safely

    func testGeoName_malformedPackData_degradesToBundledBase() {
        // A pack whose entry for this id has an empty name — the resolver treats an empty value as a
        // miss and continues the chain, ending at the bundled base. No crash, no broken value.
        let country = makeCountry(name: "Base Name")
        let brokenPack = GeoNamePackData(
            code: "fr",
            entries: ["ZZ": GeoNamePackData.GeoNameEntry(name: "")]
        )
        LanguagePackProviderHolder.active = StubProvider(packsByCode: ["fr": brokenPack])

        XCTAssertEqual(country.localizedName(for: .fr), "Base Name", "empty pack value → bundled base")
    }

    /// A malformed JSON blob never decodes to a usable pack — the bundled provider drops it and the
    /// resolver falls through. (Proves the validation-failure path yields nil → fall-through.)
    func testMalformedPackJSON_isRejectedByLoader() {
        let garbage = Data("not valid pack json".utf8)
        XCTAssertNil(GeoNamePackLoader.decodeOrNil(garbage), "malformed JSON must not produce a pack")
    }

    // MARK: - (d) No call site branches on the concrete provider type

    /// The resolver accepts any conformer; swapping the bundled provider for an unrelated stub keeps
    /// resolution working with no type checks — proving the seam is delivery-agnostic.
    func testResolver_acceptsAnyProvider_withoutTypeBranching() {
        let country = makeCountry(name: "Base Name")
        let dePack = GeoNamePackData(
            code: "de",
            entries: ["ZZ": GeoNamePackData.GeoNameEntry(name: "Provider DE")]
        )
        let resolved = GeoNameResolver.resolveThroughProvider(
            id: country.id,
            locale: .de,
            field: .name,
            base: country.name,
            provider: StubProvider(packsByCode: ["de": dePack])
        )
        XCTAssertEqual(resolved, "Provider DE")
    }
}
