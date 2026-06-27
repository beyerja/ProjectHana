import Foundation

struct River: Codable, Identifiable, Hashable {
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
    let nameJa: String?
    let nameZhHans: String?
    let nameHi: String?
    let nameBn: String?
    let namePtBr: String?
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
        nameJa: String? = nil,
        nameZhHans: String? = nil,
        nameHi: String? = nil,
        nameBn: String? = nil,
        namePtBr: String? = nil,
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
        self.nameJa = nameJa
        self.nameZhHans = nameZhHans
        self.nameHi = nameHi
        self.nameBn = nameBn
        self.namePtBr = namePtBr
        self.continent = continent
        self.sourceLat = sourceLat
        self.sourceLon = sourceLon
        self.mouthLat = mouthLat
        self.mouthLon = mouthLon
    }

    /// The localized name for `locale`, resolved through the active ``LanguagePackProvider``'s pack
    /// data keyed by this river's `id`, with the bundled English `name` as the final fallback.
    func localizedName(for locale: AppLocale) -> String {
        GeoNameResolver.resolveThroughProvider(id: id, locale: locale, field: .name, base: name)
    }
}
