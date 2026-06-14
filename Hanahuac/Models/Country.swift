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
        case .fr:   return nameFr ?? name
        case .de:   return nameDe ?? name
        case .esMX: return nameEs ?? name
        case .en:   return name
        }
    }

    func localizedCapital(for locale: AppLocale) -> String {
        switch locale {
        case .fr:   return capitalFr ?? capital
        case .de:   return capitalDe ?? capital
        case .esMX: return capitalEs ?? capital
        case .en:   return capital
        }
    }
}
