import Foundation

struct GeographyData {
    let countries: [Country]
    let rivers: [River]
    let mountains: [MountainRange]
    let seas: [Sea]
}

struct GeographyDataLoader {
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
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            fatalError("Failed to decode \(filename).json: \(error)")
        }
    }
}
