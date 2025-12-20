import XCTest
@testable import DynalinksSDK

final class APIClientTests: XCTestCase {
    var apiClient: APIClient!

    override func setUp() {
        super.setUp()
        let session = MockURLProtocol.mockSession()
        apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-api-key",
            session: session
        )
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Successful Match Tests

    func testMatchFingerprint_SuccessHighConfidence() async throws {
        let json = """
        {
            "matched": true,
            "confidence": "high",
            "match_score": 85,
            "link": {
                "id": "abc-123",
                "name": "Product Link",
                "path": "/product/shoes",
                "url": "https://example.com/product/shoes",
                "full_url": "https://app.dynalinks.app/product/shoes",
                "deep_link_value": "/product/shoes",
                "ios_deferred_deep_linking_enabled": true
            }
        }
        """
        MockURLProtocol.mockSuccess(json: json)

        let fingerprint = DeviceFingerprint.mock()
        let result = try await apiClient.matchFingerprint(fingerprint)

        XCTAssertTrue(result.matched)
        XCTAssertEqual(result.confidence, .high)
        XCTAssertEqual(result.matchScore, 85)
        XCTAssertNotNil(result.link)
        XCTAssertEqual(result.link?.id, "abc-123")
        XCTAssertEqual(result.link?.deepLinkValue, "/product/shoes")
    }

    func testMatchFingerprint_SuccessMediumConfidence() async throws {
        let json = """
        {
            "matched": true,
            "confidence": "medium",
            "match_score": 50,
            "link": {
                "id": "xyz-456",
                "path": "/promo"
            }
        }
        """
        MockURLProtocol.mockSuccess(json: json)

        let fingerprint = DeviceFingerprint.mock()
        let result = try await apiClient.matchFingerprint(fingerprint)

        XCTAssertTrue(result.matched)
        XCTAssertEqual(result.confidence, .medium)
        XCTAssertEqual(result.matchScore, 50)
    }

    func testMatchFingerprint_SuccessLowConfidence() async throws {
        let json = """
        {
            "matched": true,
            "confidence": "low",
            "match_score": 25,
            "link": {
                "id": "low-789"
            }
        }
        """
        MockURLProtocol.mockSuccess(json: json)

        let fingerprint = DeviceFingerprint.mock()
        let result = try await apiClient.matchFingerprint(fingerprint)

        XCTAssertTrue(result.matched)
        XCTAssertEqual(result.confidence, .low)
        XCTAssertEqual(result.matchScore, 25)
    }

    // MARK: - No Match Tests

    func testMatchFingerprint_NoMatch() async throws {
        let json = """
        {
            "matched": false
        }
        """
        MockURLProtocol.mockSuccess(json: json)

        let fingerprint = DeviceFingerprint.mock()
        let result = try await apiClient.matchFingerprint(fingerprint)

        XCTAssertFalse(result.matched)
        XCTAssertNil(result.confidence)
        XCTAssertNil(result.matchScore)
        XCTAssertNil(result.link)
    }

    // MARK: - Error Response Tests

    func testMatchFingerprint_Unauthorized_WrongAPIKey() async throws {
        MockURLProtocol.mockError(statusCode: 401, message: "Invalid client API key")

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            if case .serverError(let statusCode, let message) = error {
                XCTAssertEqual(statusCode, 401)
                XCTAssertEqual(message, "Invalid client API key")
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        }
    }

    func testMatchFingerprint_RateLimited() async throws {
        MockURLProtocol.mockError(statusCode: 429, message: "Rate limit exceeded")

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            if case .serverError(let statusCode, let message) = error {
                XCTAssertEqual(statusCode, 429)
                XCTAssertEqual(message, "Rate limit exceeded")
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        }
    }

    func testMatchFingerprint_ServerError_500() async throws {
        MockURLProtocol.mockError(statusCode: 500, message: "Internal server error")

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            if case .serverError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        }
    }

    func testMatchFingerprint_NotFound_404() async throws {
        MockURLProtocol.mockError(statusCode: 404, message: "Not found")

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            if case .serverError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        }
    }

    // MARK: - Network Error Tests

    func testMatchFingerprint_NetworkError_NoConnection() async throws {
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )
        MockURLProtocol.mockNetworkError(networkError)

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            if case .networkError(let underlying) = error {
                XCTAssertNotNil(underlying)
                XCTAssertEqual((underlying as NSError?)?.code, NSURLErrorNotConnectedToInternet)
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        }
    }

    func testMatchFingerprint_NetworkError_Timeout() async throws {
        let timeoutError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
        )
        MockURLProtocol.mockNetworkError(timeoutError)

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            if case .networkError(let underlying) = error {
                XCTAssertNotNil(underlying)
                XCTAssertEqual((underlying as NSError?)?.code, NSURLErrorTimedOut)
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        }
    }

    func testMatchFingerprint_NetworkError_DNSLookupFailed() async throws {
        let dnsError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCannotFindHost,
            userInfo: [NSLocalizedDescriptionKey: "A server with the specified hostname could not be found."]
        )
        MockURLProtocol.mockNetworkError(dnsError)

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            if case .networkError(let underlying) = error {
                XCTAssertEqual((underlying as NSError?)?.code, NSURLErrorCannotFindHost)
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        }
    }

    // MARK: - Invalid Response Tests

    func testMatchFingerprint_InvalidJSON() async throws {
        MockURLProtocol.mockSuccess(json: "not valid json {{{")

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            XCTAssertEqual(error, .invalidResponse)
        }
    }

    func testMatchFingerprint_MissingRequiredField() async throws {
        // Missing "matched" field which is required
        let json = """
        {
            "confidence": "high"
        }
        """
        MockURLProtocol.mockSuccess(json: json)

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            XCTAssertEqual(error, .invalidResponse)
        }
    }

    func testMatchFingerprint_EmptyResponse() async throws {
        MockURLProtocol.mockSuccess(json: "{}")

        let fingerprint = DeviceFingerprint.mock()

        do {
            _ = try await apiClient.matchFingerprint(fingerprint)
            XCTFail("Expected error to be thrown")
        } catch let error as DynalinksError {
            XCTAssertEqual(error, .invalidResponse)
        }
    }

    // MARK: - Request Validation Tests

    func testMatchFingerprint_SetsCorrectHeaders() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "{\"matched\": false}".data(using: .utf8)!)
        }

        let fingerprint = DeviceFingerprint.mock()
        _ = try await apiClient.matchFingerprint(fingerprint)

        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-api-key")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertTrue(capturedRequest?.value(forHTTPHeaderField: "User-Agent")?.contains("DynalinksSDK") ?? false)
    }

    func testMatchFingerprint_SendsFingerprintInBody() async throws {
        var capturedBody: Data?

        MockURLProtocol.requestHandler = { request in
            // Use bodyData extension which handles both httpBody and httpBodyStream
            capturedBody = request.bodyData

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "{\"matched\": false}".data(using: .utf8)!)
        }

        let fingerprint = DeviceFingerprint.mock()
        _ = try await apiClient.matchFingerprint(fingerprint)

        XCTAssertNotNil(capturedBody, "Request body should not be nil")

        // Verify the body contains fingerprint data
        if let body = capturedBody, let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            XCTAssertNotNil(json["fingerprint"], "Request should contain fingerprint key")
            if let fp = json["fingerprint"] as? [String: Any] {
                XCTAssertNotNil(fp["device_model"])
                XCTAssertNotNil(fp["os_version"])
                XCTAssertNotNil(fp["screen_width"])
                XCTAssertNotNil(fp["screen_height"])
            }
        } else {
            XCTFail("Failed to parse request body as JSON")
        }
    }

    // MARK: - Link Data Tests

    func testMatchFingerprint_ParsesAllLinkFields() async throws {
        let json = """
        {
            "matched": true,
            "confidence": "high",
            "match_score": 90,
            "link": {
                "id": "full-link-123",
                "name": "Full Test Link",
                "path": "/full/path",
                "shortened_path": "abc123",
                "url": "https://example.com/full/path?ref=email",
                "full_url": "https://app.dynalinks.app/abc123",
                "deep_link_value": "/full/path",
                "ios_deferred_deep_linking_enabled": true,
                "android_fallback_url": "https://play.google.com/store/apps/details?id=com.example",
                "ios_fallback_url": "https://apps.apple.com/app/id123456",
                "enable_forced_redirect": false,
                "social_title": "Check this out!",
                "social_description": "Amazing product",
                "social_image_url": "https://example.com/image.png",
                "clicks": 42
            }
        }
        """
        MockURLProtocol.mockSuccess(json: json)

        let fingerprint = DeviceFingerprint.mock()
        let result = try await apiClient.matchFingerprint(fingerprint)

        let link = result.link!
        XCTAssertEqual(link.id, "full-link-123")
        XCTAssertEqual(link.name, "Full Test Link")
        XCTAssertEqual(link.path, "/full/path")
        XCTAssertEqual(link.shortenedPath, "abc123")
        XCTAssertEqual(link.url, URL(string: "https://example.com/full/path?ref=email"))
        XCTAssertEqual(link.fullURL, URL(string: "https://app.dynalinks.app/abc123"))
        XCTAssertEqual(link.deepLinkValue, "/full/path")
        XCTAssertEqual(link.iosDeferredDeepLinkingEnabled, true)
        XCTAssertEqual(link.androidFallbackURL, URL(string: "https://play.google.com/store/apps/details?id=com.example"))
        XCTAssertEqual(link.iosFallbackURL, URL(string: "https://apps.apple.com/app/id123456"))
        XCTAssertEqual(link.enableForcedRedirect, false)
        XCTAssertEqual(link.socialTitle, "Check this out!")
        XCTAssertEqual(link.socialDescription, "Amazing product")
        XCTAssertEqual(link.socialImageURL, URL(string: "https://example.com/image.png"))
        XCTAssertEqual(link.clicks, 42)
    }

    func testMatchFingerprint_ParsesURLWithQueryParams() async throws {
        let json = """
        {
            "matched": true,
            "confidence": "high",
            "match_score": 85,
            "link": {
                "id": "query-link",
                "url": "https://example.com/product?ref=email&campaign=summer&promo=SAVE20"
            }
        }
        """
        MockURLProtocol.mockSuccess(json: json)

        let fingerprint = DeviceFingerprint.mock()
        let result = try await apiClient.matchFingerprint(fingerprint)

        let url = result.link!.url!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []

        XCTAssertEqual(queryItems.first(where: { $0.name == "ref" })?.value, "email")
        XCTAssertEqual(queryItems.first(where: { $0.name == "campaign" })?.value, "summer")
        XCTAssertEqual(queryItems.first(where: { $0.name == "promo" })?.value, "SAVE20")
    }
}

// MARK: - Mock Fingerprint

extension DeviceFingerprint {
    static func mock() -> DeviceFingerprint {
        return DeviceFingerprint(
            screenWidth: 393,
            screenHeight: 852,
            devicePixelRatio: 3.0,
            osVersion: "17.0",
            timezone: "America/New_York",
            language: "en-US",
            languages: ["en-US", "en"],
            countryCode: "US",
            deviceModel: "iPhone15,2",
            idfv: nil,
            appVersion: "1.0.0",
            appBuild: "1",
            simulator: false
        )
    }
}
