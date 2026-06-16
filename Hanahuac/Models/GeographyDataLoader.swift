import Foundation

struct GeographyData {
    let countries: [Country]
    let rivers: [River]
    let mountains: [MountainRange]
    let seas: [Sea]
}

enum GeographyDataLoader {
    static let shared: GeographyData = load()

    static func load() -> GeographyData {
        GeographyData(
            countries: loadJSON("countries"),
            rivers: loadJSON("rivers"),
            mountains: loadJSON("mountains"),
            seas: loadJSON("seas")
        )
    }

    static func loadJSON<T: Decodable>(_ filename: String) -> [T] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            fatalError("Missing bundled resource: \(filename).json")
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([T].self, from: data)
        } catch {
            fatalError("Failed to decode \(filename).json: \(error)")
        }
    }
}
