import Foundation

struct Country: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
    let capital: String
    let capitalFr: String?
    let capitalDe: String?
    let capitalEs: String?
    let continent: String
    let lat: Double
    let lon: Double

    func localizedName(for locale: AppLocale) -> String {
        switch locale {
        case .fr: nameFr ?? name
        case .de: nameDe ?? name
        case .esMX: nameEs ?? name
        case .en: name
        }
    }

    func localizedCapital(for locale: AppLocale) -> String {
        switch locale {
        case .fr: capitalFr ?? capital
        case .de: capitalDe ?? capital
        case .esMX: capitalEs ?? capital
        case .en: capital
        }
    }
}
