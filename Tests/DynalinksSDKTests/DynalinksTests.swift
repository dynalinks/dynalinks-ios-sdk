import XCTest
@testable import DynalinksSDK

final class DynalinksTests: XCTestCase {
    var mockSession: URLSession!
    var mockStorage: Storage!
    var mockDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        mockSession = MockURLProtocol.mockSession()
        mockDefaults = UserDefaults(suiteName: "com.dynalinks.test.\(UUID().uuidString)")!
        mockStorage = Storage(defaults: mockDefaults)

        // Reset shared instance
        Dynalinks.setShared(nil)
        DynalinksLogger.logLevel = .none // Suppress logs during tests
    }

    override func tearDown() {
        MockURLProtocol.reset()
        Dynalinks.setShared(nil)
        mockDefaults = nil
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Configuration Tests

    func testCheckForDeferredDeepLink_ThrowsNotConfigured_WhenNotConfigured() async {
        // Don't configure the SDK
        do {
            _ = try await Dynalinks.checkForDeferredDeepLink()
            XCTFail("Expected notConfigured error")
        } catch let error as DynalinksError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCheckForDeferredDeepLink_WorksAfterConfiguration() async throws {
        MockURLProtocol.mockSuccess(json: "{\"matched\": false}")

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        let result = try await Dynalinks.checkForDeferredDeepLink()
        XCTAssertFalse(result.matched)
    }

    // MARK: - Already Checked Tests

    func testCheckForDeferredDeepLink_ReturnsNoMatch_OnSecondCall() async throws {
        MockURLProtocol.mockSuccess(json: "{\"matched\": false}")

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        // First call succeeds
        let result1 = try await Dynalinks.checkForDeferredDeepLink()
        XCTAssertFalse(result1.matched)

        // Second call returns no match (doesn't throw)
        let result2 = try await Dynalinks.checkForDeferredDeepLink()
        XCTAssertFalse(result2.matched)
    }

    func testCheckForDeferredDeepLink_ReturnsCachedResult_WhenMatchedPreviously() async throws {
        let matchedJson = """
        {
            "matched": true,
            "confidence": "high",
            "match_score": 85,
            "link": {"id": "cached-123", "path": "/cached"}
        }
        """
        MockURLProtocol.mockSuccess(json: matchedJson)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        // First call - gets from API
        let result1 = try await Dynalinks.checkForDeferredDeepLink()
        XCTAssertTrue(result1.matched)
        XCTAssertEqual(result1.link?.id, "cached-123")

        // Change mock to return different result (shouldn't be used)
        MockURLProtocol.mockSuccess(json: "{\"matched\": false}")

        // Second call - returns cached result
        let result2 = try await Dynalinks.checkForDeferredDeepLink()
        XCTAssertTrue(result2.matched)
        XCTAssertEqual(result2.link?.id, "cached-123")
    }

    // MARK: - Reset Tests

    func testReset_AllowsCheckAgain() async throws {
        MockURLProtocol.mockSuccess(json: "{\"matched\": false}")

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        // First call
        _ = try await Dynalinks.checkForDeferredDeepLink()

        // Reset
        Dynalinks.reset()

        // Should make a fresh API call after reset
        let result = try await Dynalinks.checkForDeferredDeepLink()
        XCTAssertFalse(result.matched)
    }

    func testReset_ClearsCachedResult() async throws {
        let matchedJson = """
        {
            "matched": true,
            "confidence": "high",
            "match_score": 85,
            "link": {"id": "to-be-cleared"}
        }
        """
        MockURLProtocol.mockSuccess(json: matchedJson)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        // First call - gets match
        _ = try await Dynalinks.checkForDeferredDeepLink()

        // Reset
        Dynalinks.reset()

        // Change mock to no match
        MockURLProtocol.mockSuccess(json: "{\"matched\": false}")

        // Should get new result, not cached
        let result = try await Dynalinks.checkForDeferredDeepLink()
        XCTAssertFalse(result.matched)
    }

    // MARK: - Error Propagation Tests

    func testCheckForDeferredDeepLink_PropagatesNetworkError() async {
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        )
        MockURLProtocol.mockNetworkError(networkError)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        do {
            _ = try await Dynalinks.checkForDeferredDeepLink()
            XCTFail("Expected networkError")
        } catch let error as DynalinksError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCheckForDeferredDeepLink_PropagatesServerError() async {
        MockURLProtocol.mockError(statusCode: 401, message: "Invalid API key")

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "wrong-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        do {
            _ = try await Dynalinks.checkForDeferredDeepLink()
            XCTFail("Expected serverError")
        } catch let error as DynalinksError {
            if case .serverError(let code, _) = error {
                XCTAssertEqual(code, 401)
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCheckForDeferredDeepLink_PropagatesRateLimitError() async {
        MockURLProtocol.mockError(statusCode: 429, message: "Rate limit exceeded")

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        do {
            _ = try await Dynalinks.checkForDeferredDeepLink()
            XCTFail("Expected serverError")
        } catch let error as DynalinksError {
            if case .serverError(let code, let message) = error {
                XCTAssertEqual(code, 429)
                XCTAssertEqual(message, "Rate limit exceeded")
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Completion Handler Tests

    func testCheckForDeferredDeepLink_CompletionHandler_Success() {
        let expectation = expectation(description: "Completion called")

        MockURLProtocol.mockSuccess(json: """
        {
            "matched": true,
            "confidence": "high",
            "match_score": 85,
            "link": {"id": "completion-test"}
        }
        """)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        Dynalinks.checkForDeferredDeepLink { result in
            switch result {
            case .success(let deepLinkResult):
                XCTAssertTrue(deepLinkResult.matched)
                XCTAssertEqual(deepLinkResult.link?.id, "completion-test")
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCheckForDeferredDeepLink_CompletionHandler_Failure() {
        let expectation = expectation(description: "Completion called")

        MockURLProtocol.mockError(statusCode: 500)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        Dynalinks.checkForDeferredDeepLink { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    // MARK: - End-to-End Flow Tests

    func testFullFlow_MatchFound_HighConfidence() async throws {
        let json = """
        {
            "matched": true,
            "confidence": "high",
            "match_score": 92,
            "link": {
                "id": "e2e-link-123",
                "name": "E2E Test Link",
                "path": "/e2e/test",
                "url": "https://example.com/e2e/test?campaign=test",
                "full_url": "https://app.dynalinks.app/e2e/test",
                "deep_link_value": "/e2e/test",
                "ios_deferred_deep_linking_enabled": true
            }
        }
        """
        MockURLProtocol.mockSuccess(json: json)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "valid-api-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        let result = try await Dynalinks.checkForDeferredDeepLink()

        XCTAssertTrue(result.matched)
        XCTAssertEqual(result.confidence, .high)
        XCTAssertEqual(result.matchScore, 92)
        XCTAssertEqual(result.link?.id, "e2e-link-123")
        XCTAssertEqual(result.link?.name, "E2E Test Link")
        XCTAssertEqual(result.link?.deepLinkValue, "/e2e/test")
        XCTAssertEqual(result.link?.url, URL(string: "https://example.com/e2e/test?campaign=test"))
        XCTAssertEqual(result.link?.iosDeferredDeepLinkingEnabled, true)

        // Verify cached
        XCTAssertTrue(mockStorage.hasCheckedForDeferredDeepLink)
        XCTAssertNotNil(mockStorage.cachedResult)
    }

    func testFullFlow_NoMatch() async throws {
        MockURLProtocol.mockSuccess(json: "{\"matched\": false}")

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "valid-api-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        let result = try await Dynalinks.checkForDeferredDeepLink()

        XCTAssertFalse(result.matched)
        XCTAssertNil(result.link)

        // Should still mark as checked but not cache result
        XCTAssertTrue(mockStorage.hasCheckedForDeferredDeepLink)
        XCTAssertNil(mockStorage.cachedResult)
    }

    func testFullFlow_NetworkError_DoesNotMarkAsChecked() async {
        MockURLProtocol.mockNetworkError(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        do {
            _ = try await Dynalinks.checkForDeferredDeepLink()
        } catch {
            // Expected
        }

        // Network error should not mark as checked (allows retry)
        XCTAssertFalse(mockStorage.hasCheckedForDeferredDeepLink)
    }

    // MARK: - Handle Universal Link Tests

    func testHandleUniversalLink_ThrowsNotConfigured_WhenNotConfigured() async {
        do {
            _ = try await Dynalinks.handleUniversalLink(url: URL(string: "https://example.com/path")!)
            XCTFail("Expected notConfigured error")
        } catch let error as DynalinksError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHandleUniversalLink_ReturnsMatchedLink() async throws {
        let json = """
        {
            "matched": true,
            "link": {
                "id": "universal-link-123",
                "path": "/test-path",
                "deep_link_value": "/test-path",
                "full_url": "https://app.dynalinks.app/test-path"
            }
        }
        """
        MockURLProtocol.mockSuccess(json: json)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        let result = try await Dynalinks.handleUniversalLink(
            url: URL(string: "https://project.dynalinks.app/test-path")!
        )

        XCTAssertTrue(result.matched)
        XCTAssertEqual(result.link?.id, "universal-link-123")
        XCTAssertEqual(result.link?.path, "/test-path")
    }

    func testHandleUniversalLink_ReturnsNoMatch_WhenLinkNotFound() async throws {
        MockURLProtocol.mockSuccess(json: "{\"matched\": false}")

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        let result = try await Dynalinks.handleUniversalLink(
            url: URL(string: "https://project.dynalinks.app/nonexistent")!
        )

        XCTAssertFalse(result.matched)
        XCTAssertNil(result.link)
    }

    func testHandleUniversalLink_MarksAsChecked_SkipsDeferredCheck() async throws {
        MockURLProtocol.mockSuccess(json: """
        {
            "matched": true,
            "link": {"id": "ul-123", "path": "/ul-path"}
        }
        """)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        // Handle Universal Link first
        let ulResult = try await Dynalinks.handleUniversalLink(
            url: URL(string: "https://project.dynalinks.app/ul-path")!
        )
        XCTAssertTrue(ulResult.matched)

        // Change mock to return different result
        MockURLProtocol.mockSuccess(json: """
        {
            "matched": true,
            "link": {"id": "different-123"}
        }
        """)

        // Deferred check should return cached result from Universal Link
        let deferredResult = try await Dynalinks.checkForDeferredDeepLink()
        XCTAssertTrue(deferredResult.matched)
        XCTAssertEqual(deferredResult.link?.id, "ul-123") // Cached from UL, not new API call
    }

    func testHandleUniversalLink_CachesResult() async throws {
        MockURLProtocol.mockSuccess(json: """
        {
            "matched": true,
            "link": {"id": "cached-ul-123", "path": "/cached"}
        }
        """)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        _ = try await Dynalinks.handleUniversalLink(
            url: URL(string: "https://project.dynalinks.app/cached")!
        )

        XCTAssertTrue(mockStorage.hasCheckedForDeferredDeepLink)
        XCTAssertNotNil(mockStorage.cachedResult)
        XCTAssertEqual(mockStorage.cachedResult?.link?.id, "cached-ul-123")
    }

    func testHandleUniversalLink_CompletionHandler_Success() {
        let expectation = expectation(description: "Completion called")

        MockURLProtocol.mockSuccess(json: """
        {
            "matched": true,
            "link": {"id": "completion-ul-123"}
        }
        """)

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "test-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        Dynalinks.handleUniversalLink(url: URL(string: "https://example.com/path")!) { result in
            switch result {
            case .success(let deepLinkResult):
                XCTAssertTrue(deepLinkResult.matched)
                XCTAssertEqual(deepLinkResult.link?.id, "completion-ul-123")
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testHandleUniversalLink_PropagatesServerError() async {
        MockURLProtocol.mockError(statusCode: 401, message: "Invalid client API key")

        let apiClient = APIClient(
            baseURL: URL(string: "https://test.dynalinks.app/api/v1")!,
            clientAPIKey: "wrong-key",
            session: mockSession,
            maxRetries: 0
        )
        let sdk = Dynalinks(apiClient: apiClient, storage: mockStorage, allowSimulator: true)
        Dynalinks.setShared(sdk)

        do {
            _ = try await Dynalinks.handleUniversalLink(url: URL(string: "https://example.com/path")!)
            XCTFail("Expected serverError")
        } catch let error as DynalinksError {
            if case .serverError(let code, _) = error {
                XCTAssertEqual(code, 401)
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
