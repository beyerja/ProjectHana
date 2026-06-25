import Foundation

struct Country: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
    let nameEsEs: String?
    let nameCa: String?
    let nameEu: String?
    let nameYua: String?
    let nameIt: String?
    let namePl: String?
    let nameNl: String?
    let nameSr: String?
    let nameKo: String?
    let nameNah: String?
    let capital: String
    let capitalFr: String?
    let capitalDe: String?
    let capitalEs: String?
    let capitalEsEs: String?
    let capitalCa: String?
    let capitalEu: String?
    let capitalYua: String?
    let capitalIt: String?
    let capitalPl: String?
    let capitalNl: String?
    let capitalSr: String?
    let capitalKo: String?
    let capitalNah: String?
    let continent: String
    let lat: Double
    let lon: Double

    /// Explicit memberwise init so the Korean/Nahuatl name and capital fields default to `nil`.
    /// This keeps existing call sites (decoding + tests) source-compatible while the ko/nah content
    /// is populated incrementally; `Codable` still decodes the optionals when the JSON keys exist.
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
        nameIt: String? = nil,
        namePl: String? = nil,
        nameNl: String? = nil,
        nameSr: String? = nil,
        nameKo: String? = nil,
        nameNah: String? = nil,
        capital: String,
        capitalFr: String?,
        capitalDe: String?,
        capitalEs: String?,
        capitalEsEs: String? = nil,
        capitalCa: String? = nil,
        capitalEu: String? = nil,
        capitalYua: String? = nil,
        capitalIt: String? = nil,
        capitalPl: String? = nil,
        capitalNl: String? = nil,
        capitalSr: String? = nil,
        capitalKo: String? = nil,
        capitalNah: String? = nil,
        continent: String,
        lat: Double,
        lon: Double
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
        self.nameIt = nameIt
        self.namePl = namePl
        self.nameNl = nameNl
        self.nameSr = nameSr
        self.nameKo = nameKo
        self.nameNah = nameNah
        self.capital = capital
        self.capitalFr = capitalFr
        self.capitalDe = capitalDe
        self.capitalEs = capitalEs
        self.capitalEsEs = capitalEsEs
        self.capitalCa = capitalCa
        self.capitalEu = capitalEu
        self.capitalYua = capitalYua
        self.capitalIt = capitalIt
        self.capitalPl = capitalPl
        self.capitalNl = capitalNl
        self.capitalSr = capitalSr
        self.capitalKo = capitalKo
        self.capitalNah = capitalNah
        self.continent = continent
        self.lat = lat
        self.lon = lon
    }

    /// The localized name for `locale`, resolved through the active ``LanguagePackProvider``'s pack
    /// data keyed by this country's `id`, walking the fallback chain (selected → es-MX for ko/nah →
    /// en) and falling back to the bundled English `name` when no pack carries a value.
    func localizedName(for locale: AppLocale) -> String {
        GeoNameResolver.resolveThroughProvider(id: id, locale: locale, field: .name, base: name)
    }

    /// The localized capital for `locale`, resolved through the active ``LanguagePackProvider``'s
    /// pack data keyed by this country's `id`, with the bundled English `capital` as the final
    /// fallback.
    func localizedCapital(for locale: AppLocale) -> String {
        GeoNameResolver.resolveThroughProvider(id: id, locale: locale, field: .capital, base: capital)
    }
}
