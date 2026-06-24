import Foundation

struct MountainRange: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
    let nameEsEs: String?
    let nameCa: String?
    let nameEu: String?
    let nameYua: String?
    let nameKo: String?
    let nameNah: String?
    let continent: String
    let lat: Double
    let lon: Double
    let highestPeak: String
    let elevationMetres: Int

    /// Explicit memberwise init defaulting the ko/nah names to `nil` so existing call sites stay
    /// source-compatible; `Codable` still decodes them when the JSON keys are present.
    init(
        id: String,
        name: String,
        nameFr: String?,
        nameDe: String?,
        nameEs: String?,
        nameEsEs: String? = nil,
        nameCa: String? = nil,
        nameEu: String? = nil,
        nameYua: String? = nil,
        nameKo: String? = nil,
        nameNah: String? = nil,
        continent: String,
        lat: Double,
        lon: Double,
        highestPeak: String,
        elevationMetres: Int
    ) {
        self.id = id
        self.name = name
        self.nameFr = nameFr
        self.nameDe = nameDe
        self.nameEs = nameEs
        self.nameEsEs = nameEsEs
        self.nameCa = nameCa
        self.nameEu = nameEu
        self.nameYua = nameYua
        self.nameKo = nameKo
        self.nameNah = nameNah
        self.continent = continent
        self.lat = lat
        self.lon = lon
        self.highestPeak = highestPeak
        self.elevationMetres = elevationMetres
    }

    /// The localized name for `locale`, resolved through the active ``LanguagePackProvider``'s pack
    /// data keyed by this range's `id`, with the bundled English `name` as the final fallback.
    func localizedName(for locale: AppLocale) -> String {
        GeoNameResolver.resolveThroughProvider(id: id, locale: locale, field: .name, base: name)
    }
}
