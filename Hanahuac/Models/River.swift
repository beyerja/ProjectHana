import Foundation

struct River: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
    let nameKo: String?
    let nameNah: String?
    let continent: String
    let sourceLat: Double
    let sourceLon: Double
    let mouthLat: Double
    let mouthLon: Double

    /// Explicit memberwise init defaulting the ko/nah names to `nil` so existing call sites stay
    /// source-compatible; `Codable` still decodes them when the JSON keys are present.
    init(
        id: String,
        name: String,
        nameFr: String?,
        nameDe: String?,
        nameEs: String?,
        nameKo: String? = nil,
        nameNah: String? = nil,
        continent: String,
        sourceLat: Double,
        sourceLon: Double,
        mouthLat: Double,
        mouthLon: Double
    ) {
        self.id = id
        self.name = name
        self.nameFr = nameFr
        self.nameDe = nameDe
        self.nameEs = nameEs
        self.nameKo = nameKo
        self.nameNah = nameNah
        self.continent = continent
        self.sourceLat = sourceLat
        self.sourceLon = sourceLon
        self.mouthLat = mouthLat
        self.mouthLon = mouthLon
    }

    /// Per-language names keyed by language code, consumed by ``GeoNameResolver`` instead of a
    /// hardcoded per-locale `switch`.
    private var namesByCode: [String: String] {
        [
            AppLocale.fr.rawValue: nameFr,
            AppLocale.de.rawValue: nameDe,
            AppLocale.esMX.rawValue: nameEs,
            AppLocale.ko.rawValue: nameKo,
            AppLocale.nah.rawValue: nameNah
        ].compactMapValues { $0 }
    }

    func localizedName(for locale: AppLocale) -> String {
        GeoNameResolver.resolve(locale, byCode: namesByCode, base: name)
    }
}
