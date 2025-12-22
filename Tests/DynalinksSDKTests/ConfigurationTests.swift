import XCTest
@testable import DynalinksSDK

final class ConfigurationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Dynalinks.setShared(nil)
        DynalinksLogger.logLevel = .none
    }

    override func tearDown() {
        Dynalinks.setShared(nil)
        super.tearDown()
    }

    // MARK: - Valid API Key Tests

    func testConfigure_AcceptsUUID() throws {
        XCTAssertNoThrow(try Dynalinks.configure(
            clientAPIKey: "550e8400-e29b-41d4-a716-446655440000"
        ))
    }

    func testConfigure_AcceptsSecureToken() throws {
        XCTAssertNoThrow(try Dynalinks.configure(
            clientAPIKey: "ec154c6ae0d897a40e201f7368d606ea"
        ))
    }

    func testConfigure_AcceptsPlainText() throws {
        XCTAssertNoThrow(try Dynalinks.configure(
            clientAPIKey: "my-api-key"
        ))
    }

    func testConfigure_AcceptsShortKey() throws {
        XCTAssertNoThrow(try Dynalinks.configure(
            clientAPIKey: "abc123"
        ))
    }

    // MARK: - Invalid API Key Tests

    func testConfigure_RejectsEmptyString() {
        XCTAssertThrowsError(try Dynalinks.configure(clientAPIKey: "")) { error in
            guard let dynalinksError = error as? DynalinksError else {
                XCTFail("Expected DynalinksError")
                return
            }
            if case .invalidAPIKey(let message) = dynalinksError {
                XCTAssertEqual(message, "Client API key cannot be empty")
            } else {
                XCTFail("Expected invalidAPIKey error")
            }
        }
    }

    // MARK: - Error Message Tests

    func testInvalidAPIKey_HasCorrectErrorDescription() {
        let error = DynalinksError.invalidAPIKey("Test message")
        XCTAssertEqual(error.errorDescription, "Invalid API key: Test message")
    }

    func testInvalidAPIKey_IsEquatable() {
        let error1 = DynalinksError.invalidAPIKey("Message A")
        let error2 = DynalinksError.invalidAPIKey("Message A")
        let error3 = DynalinksError.invalidAPIKey("Message B")

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
}
