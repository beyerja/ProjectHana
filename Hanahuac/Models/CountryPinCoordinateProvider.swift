import CoreLocation

/// Provides guaranteed-interior pin coordinates for every country that has border data.
///
/// For each country with a matching entry in `country-borders.json`, the provider selects
/// the ring with the most vertices (taken as the mainland polygon) and computes the pole
/// of inaccessibility via `PoleLabelCalculator`. The result is a point guaranteed to be
/// inside the mainland polygon, regardless of how concave or fjord-heavy the coastline is.
///
/// For countries with no border data (small island nations, micro-states), the provider
/// falls back to the raw `lat`/`lon` from `countries.json`.
///
/// The computed coordinates are cached in a dictionary at first access and reused for
/// the lifetime of the app.
struct CountryPinCoordinateProvider {

    // MARK: - Shared instance

    static let shared = CountryPinCoordinateProvider()

    // MARK: - Private storage

    /// Maps country ISO id → computed pole-of-inaccessibility coordinate.
    private let computed: [String: CLLocationCoordinate2D]

    // MARK: - Init

    init(borders: [String: [[CLLocationCoordinate2D]]] = CountryBorderLoader.shared) {
        var cache: [String: CLLocationCoordinate2D] = [:]
        for (id, rings) in borders {
            guard let mainland = rings.max(by: { $0.count < $1.count }),
                  let pole = PoleLabelCalculator.compute(ring: mainland) else { continue }
            cache[id] = pole
        }
        self.computed = cache
    }

    // MARK: - Public API

    /// Returns the best pin coordinate for `country`:
    /// - The pole of inaccessibility of the mainland border ring, if border data is available.
    /// - The raw `country.lat` / `country.lon` from `countries.json` otherwise.
    func coordinate(for country: Country) -> CLLocationCoordinate2D {
        if let coord = computed[country.id] {
            return coord
        }
        return CLLocationCoordinate2D(latitude: country.lat, longitude: country.lon)
    }
}
