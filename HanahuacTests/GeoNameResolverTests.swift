import XCTest
@testable import Hanahuac

/// `GeoNameResolver` reproduces the previous per-field-switch outputs across every fallback chain.
final class GeoNameResolverTests: XCTestCase {
    func testResolve_directValue_whenPresent() {
        let byCode = ["fr": "Rhin", "de": "Rhein"]
        XCTAssertEqual(GeoNameResolver.resolve(.fr, byCode: byCode, base: "Rhine"), "Rhin")
        XCTAssertEqual(GeoNameResolver.resolve(.de, byCode: byCode, base: "Rhine"), "Rhein")
    }

    func testResolve_fallsBackToBase_whenMissing() {
        XCTAssertEqual(GeoNameResolver.resolve(.fr, byCode: [:], base: "Rhine"), "Rhine")
        XCTAssertEqual(GeoNameResolver.resolve(.de, byCode: [:], base: "Rhine"), "Rhine")
        XCTAssertEqual(GeoNameResolver.resolve(.esMX, byCode: [:], base: "Rhine"), "Rhine")
    }

    func testResolve_koAndNah_walkThroughSpanishBeforeEnglish() {
        let byCode = ["es-MX": "Rin"]
        // ko/nah have no own value but Spanish is present → Mexican Spanish, not English.
        XCTAssertEqual(GeoNameResolver.resolve(.ko, byCode: byCode, base: "Rhine"), "Rin")
        XCTAssertEqual(GeoNameResolver.resolve(.nah, byCode: byCode, base: "Rhine"), "Rin")
    }

    func testResolve_koAndNah_ownValueWins() {
        let byCode = ["ko": "라인강", "nah": "Rīn", "es-MX": "Rin"]
        XCTAssertEqual(GeoNameResolver.resolve(.ko, byCode: byCode, base: "Rhine"), "라인강")
        XCTAssertEqual(GeoNameResolver.resolve(.nah, byCode: byCode, base: "Rhine"), "Rīn")
    }

    func testResolve_koAndNah_fallBackToBase_whenSpanishAlsoMissing() {
        XCTAssertEqual(GeoNameResolver.resolve(.ko, byCode: [:], base: "Rhine"), "Rhine")
        XCTAssertEqual(GeoNameResolver.resolve(.nah, byCode: [:], base: "Rhine"), "Rhine")
    }

    func testResolve_emptyStringValue_isSkipped() {
        // An empty value in the chain must not win; resolution continues to the base.
        XCTAssertEqual(GeoNameResolver.resolve(.fr, byCode: ["fr": ""], base: "Rhine"), "Rhine")
    }

    func testResolve_en_alwaysReturnsBase() {
        XCTAssertEqual(GeoNameResolver.resolve(.en, byCode: ["fr": "Rhin"], base: "Rhine"), "Rhine")
    }
}
