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

    func localizedName(for locale: AppLocale) -> String {
        switch locale {
        case .fr: nameFr ?? name
        case .de: nameDe ?? name
        case .esMX: nameEs ?? name
        case .ko: nameKo ?? nameEs ?? name
        case .nah: nameNah ?? nameEs ?? name
        case .en: name
        }
    }
}
