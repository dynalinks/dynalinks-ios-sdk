import XCTest
@testable import DynalinksSDK

final class DeviceFingerprintTests: XCTestCase {

    func testOSVersionNormalization() {
        // Test via the public fingerprint collection
        let fingerprint = DeviceFingerprint.collect()

        // OS version should be in X.Y.Z format
        let parts = fingerprint.osVersion.split(separator: ".")
        XCTAssertEqual(parts.count, 3, "OS version should have 3 parts")

        // Each part should be a number
        for part in parts {
            XCTAssertNotNil(Int(part), "Each OS version part should be a number")
        }
    }

    func testFingerprintCollection() {
        let fingerprint = DeviceFingerprint.collect()

        // Screen dimensions should be positive
        XCTAssertGreaterThan(fingerprint.screenWidth, 0)
        XCTAssertGreaterThan(fingerprint.screenHeight, 0)
        XCTAssertGreaterThan(fingerprint.devicePixelRatio, 0)

        // Required fields should not be empty
        XCTAssertFalse(fingerprint.osVersion.isEmpty)
        XCTAssertFalse(fingerprint.timezone.isEmpty)
        XCTAssertFalse(fingerprint.language.isEmpty)
        XCTAssertFalse(fingerprint.languages.isEmpty)
        XCTAssertFalse(fingerprint.deviceModel.isEmpty)

        // Simulator detection
        #if targetEnvironment(simulator)
        XCTAssertTrue(fingerprint.simulator)
        #else
        XCTAssertFalse(fingerprint.simulator)
        #endif
    }

    func testFingerprintEncoding() throws {
        let fingerprint = DeviceFingerprint.collect()

        // Should be encodable to JSON
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(fingerprint)

        // Should produce valid JSON
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)

        // Check key names are snake_case
        XCTAssertNotNil(json?["screen_width"])
        XCTAssertNotNil(json?["screen_height"])
        XCTAssertNotNil(json?["device_pixel_ratio"])
        XCTAssertNotNil(json?["os_version"])
    }
}
