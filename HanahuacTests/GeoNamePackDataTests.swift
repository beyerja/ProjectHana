import XCTest
@testable import Hanahuac

/// Schema-validation and safe-loader behavior for `GeoNamePackData` / `GeoNamePackLoader`.
final class GeoNamePackDataTests: XCTestCase {
    // MARK: - Well-formed packs

    func testDecode_wellFormedPack_succeeds() throws {
        let json = Data(
            """
            {
              "version": 1,
              "code": "fr",
              "entries": {
                "DE": { "name": "Allemagne", "capital": "Berlin" },
                "rhine": { "name": "Rhin" }
              }
            }
            """.utf8
        )

        let pack = try GeoNamePackLoader.decode(json)
        XCTAssertEqual(pack.version, 1)
        XCTAssertEqual(pack.code, "fr")
        XCTAssertEqual(pack.entries["DE"]?.name, "Allemagne")
        XCTAssertEqual(pack.entries["DE"]?.capital, "Berlin")
        XCTAssertEqual(pack.entries["rhine"]?.name, "Rhin")
        XCTAssertNil(pack.entries["rhine"]?.capital)
    }

    func testRoundTrip_encodeThenDecode_preservesData() throws {
        let pack = GeoNamePackData(
            code: "ko",
            entries: ["JP": GeoNamePackData.GeoNameEntry(name: "일본", capital: "도쿄")]
        )
        let encoded = try JSONEncoder().encode(pack)
        let decoded = try GeoNamePackLoader.decode(encoded)
        XCTAssertEqual(decoded, pack)
    }

    // MARK: - Malformed / unsupported packs degrade safely (never crash)

    func testDecode_malformedJSON_throwsTypedError() {
        let junk = Data("not json at all".utf8)
        XCTAssertThrowsError(try GeoNamePackLoader.decode(junk)) { error in
            XCTAssertEqual(error as? GeoNamePackError, .malformedJSON)
        }
    }

    func testDecode_unsupportedVersion_throwsTypedError() {
        let json = Data(
            """
            { "version": 999, "code": "fr", "entries": { "DE": { "name": "Allemagne" } } }
            """.utf8
        )
        XCTAssertThrowsError(try GeoNamePackLoader.decode(json)) { error in
            XCTAssertEqual(error as? GeoNamePackError, .unsupportedVersion(999))
        }
    }

    func testDecode_emptyCode_throwsTypedError() {
        let json = Data(
            """
            { "version": 1, "code": "", "entries": { "DE": { "name": "X" } } }
            """.utf8
        )
        XCTAssertThrowsError(try GeoNamePackLoader.decode(json)) { error in
            XCTAssertEqual(error as? GeoNamePackError, .emptyLanguageCode)
        }
    }

    func testDecode_entryWithNoNameOrCapital_throwsTypedError() {
        let json = Data(
            """
            { "version": 1, "code": "fr", "entries": { "DE": { "name": null, "capital": null } } }
            """.utf8
        )
        XCTAssertThrowsError(try GeoNamePackLoader.decode(json)) { error in
            XCTAssertEqual(error as? GeoNamePackError, .invalidEntry(id: "DE"))
        }
    }

    /// The nil-returning convenience never throws — it degrades to nil so callers fall back.
    func testDecodeOrNil_onFailure_returnsNilNotCrash() {
        XCTAssertNil(GeoNamePackLoader.decodeOrNil(Data("{".utf8)))
        let bad = Data(#"{ "version": 7, "code": "x", "entries": {} }"#.utf8)
        XCTAssertNil(GeoNamePackLoader.decodeOrNil(bad))
    }
}
