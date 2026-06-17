import Foundation

struct Country: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
    let nameKo: String?
    let nameNah: String?
    let capital: String
    let capitalFr: String?
    let capitalDe: String?
    let capitalEs: String?
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
        nameKo: String? = nil,
        nameNah: String? = nil,
        capital: String,
        capitalFr: String?,
        capitalDe: String?,
        capitalEs: String?,
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
        self.nameKo = nameKo
        self.nameNah = nameNah
        self.capital = capital
        self.capitalFr = capitalFr
        self.capitalDe = capitalDe
        self.capitalEs = capitalEs
        self.capitalKo = capitalKo
        self.capitalNah = capitalNah
        self.continent = continent
        self.lat = lat
        self.lon = lon
    }

    func localizedName(for locale: AppLocale) -> String {
        switch locale {
        case .fr: nameFr ?? name
        case .de: nameDe ?? name
        case .esMX: nameEs ?? name
        // ko/nah: selected language → Mexican Spanish → English.
        case .ko: nameKo ?? nameEs ?? name
        case .nah: nameNah ?? nameEs ?? name
        case .en: name
        }
    }

    func localizedCapital(for locale: AppLocale) -> String {
        switch locale {
        case .fr: capitalFr ?? capital
        case .de: capitalDe ?? capital
        case .esMX: capitalEs ?? capital
        case .ko: capitalKo ?? capitalEs ?? capital
        case .nah: capitalNah ?? capitalEs ?? capital
        case .en: capital
        }
    }
}
