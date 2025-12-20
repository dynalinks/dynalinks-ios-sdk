import XCTest
@testable import DynalinksSDK

final class ConfigurationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Dynalinks.setShared(nil)
        Logger.logLevel = .none
    }

    override func tearDown() {
        Dynalinks.setShared(nil)
        super.tearDown()
    }

    // MARK: - Valid API Key Tests

    func testConfigure_AcceptsValidUUID() throws {
        XCTAssertNoThrow(try Dynalinks.configure(
            clientAPIKey: "550e8400-e29b-41d4-a716-446655440000"
        ))
    }

    func testConfigure_AcceptsUppercaseUUID() throws {
        XCTAssertNoThrow(try Dynalinks.configure(
            clientAPIKey: "550E8400-E29B-41D4-A716-446655440000"
        ))
    }

    func testConfigure_AcceptsLowercaseUUID() throws {
        XCTAssertNoThrow(try Dynalinks.configure(
            clientAPIKey: "550e8400-e29b-41d4-a716-446655440000"
        ))
    }

    func testConfigure_AcceptsMixedCaseUUID() throws {
        XCTAssertNoThrow(try Dynalinks.configure(
            clientAPIKey: "550e8400-E29B-41d4-A716-446655440000"
        ))
    }

    func testConfigure_AcceptsZeroUUID() throws {
        XCTAssertNoThrow(try Dynalinks.configure(
            clientAPIKey: "00000000-0000-0000-0000-000000000000"
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
                XCTAssertEqual(message, "Client API key must be a valid UUID")
            } else {
                XCTFail("Expected invalidAPIKey error")
            }
        }
    }

    func testConfigure_RejectsPlainText() {
        XCTAssertThrowsError(try Dynalinks.configure(clientAPIKey: "my-api-key")) { error in
            guard let dynalinksError = error as? DynalinksError else {
                XCTFail("Expected DynalinksError")
                return
            }
            XCTAssertEqual(dynalinksError, .invalidAPIKey("Client API key must be a valid UUID"))
        }
    }

    func testConfigure_RejectsUUIDWithoutHyphens() {
        XCTAssertThrowsError(try Dynalinks.configure(
            clientAPIKey: "550e8400e29b41d4a716446655440000"
        )) { error in
            XCTAssertTrue(error is DynalinksError)
        }
    }

    func testConfigure_RejectsUUIDWithExtraCharacters() {
        XCTAssertThrowsError(try Dynalinks.configure(
            clientAPIKey: "550e8400-e29b-41d4-a716-446655440000-extra"
        )) { error in
            XCTAssertTrue(error is DynalinksError)
        }
    }

    func testConfigure_RejectsTruncatedUUID() {
        XCTAssertThrowsError(try Dynalinks.configure(
            clientAPIKey: "550e8400-e29b-41d4-a716"
        )) { error in
            XCTAssertTrue(error is DynalinksError)
        }
    }

    func testConfigure_RejectsInvalidCharacters() {
        XCTAssertThrowsError(try Dynalinks.configure(
            clientAPIKey: "550e8400-e29b-41d4-a716-44665544000g"  // 'g' is not hex
        )) { error in
            XCTAssertTrue(error is DynalinksError)
        }
    }

    func testConfigure_RejectsWhitespace() {
        XCTAssertThrowsError(try Dynalinks.configure(
            clientAPIKey: " 550e8400-e29b-41d4-a716-446655440000"
        )) { error in
            XCTAssertTrue(error is DynalinksError)
        }
    }

    func testConfigure_RejectsNewlines() {
        XCTAssertThrowsError(try Dynalinks.configure(
            clientAPIKey: "550e8400-e29b-41d4-a716-446655440000\n"
        )) { error in
            XCTAssertTrue(error is DynalinksError)
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
