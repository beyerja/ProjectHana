import Foundation

struct MountainRange: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
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
        self.nameKo = nameKo
        self.nameNah = nameNah
        self.continent = continent
        self.lat = lat
        self.lon = lon
        self.highestPeak = highestPeak
        self.elevationMetres = elevationMetres
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
