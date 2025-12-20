import XCTest
@testable import DynalinksSDK

final class StorageTests: XCTestCase {
    var storage: Storage!
    var mockDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use a unique suite name for each test to ensure isolation
        mockDefaults = UserDefaults(suiteName: "com.dynalinks.test.\(UUID().uuidString)")!
        storage = Storage(defaults: mockDefaults)
    }

    override func tearDown() {
        // Clean up the test suite
        if let suiteName = mockDefaults.volatileDomainNames.first {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
        mockDefaults = nil
        storage = nil
        super.tearDown()
    }

    // MARK: - hasCheckedForDeferredDeepLink Tests

    func testHasCheckedForDeferredDeepLink_DefaultsFalse() {
        XCTAssertFalse(storage.hasCheckedForDeferredDeepLink)
    }

    func testHasCheckedForDeferredDeepLink_CanBeSetToTrue() {
        storage.hasCheckedForDeferredDeepLink = true
        XCTAssertTrue(storage.hasCheckedForDeferredDeepLink)
    }

    func testHasCheckedForDeferredDeepLink_CanBeSetBackToFalse() {
        storage.hasCheckedForDeferredDeepLink = true
        storage.hasCheckedForDeferredDeepLink = false
        XCTAssertFalse(storage.hasCheckedForDeferredDeepLink)
    }

    func testHasCheckedForDeferredDeepLink_PersistsAcrossInstances() {
        storage.hasCheckedForDeferredDeepLink = true

        // Create new storage instance with same defaults
        let newStorage = Storage(defaults: mockDefaults)
        XCTAssertTrue(newStorage.hasCheckedForDeferredDeepLink)
    }

    // MARK: - cachedResult Tests

    func testCachedResult_DefaultsNil() {
        XCTAssertNil(storage.cachedResult)
    }

    func testCachedResult_CanStoreAndRetrieveMatchedResult() {
        let result = DeepLinkResult(
            matched: true,
            confidence: .high,
            matchScore: 85,
            link: DeepLinkResult.LinkData(
                id: "test-123",
                name: "Test Link",
                path: "/test/path",
                shortenedPath: nil,
                url: URL(string: "https://example.com"),
                fullURL: URL(string: "https://app.dynalinks.app/test"),
                deepLinkValue: "/test/path",
                iosDeferredDeepLinkingEnabled: true,
                androidFallbackURL: nil,
                iosFallbackURL: nil,
                enableForcedRedirect: nil,
                socialTitle: nil,
                socialDescription: nil,
                socialImageURL: nil,
                clicks: nil
            )
        )

        storage.cachedResult = result
        let retrieved = storage.cachedResult

        XCTAssertNotNil(retrieved)
        XCTAssertTrue(retrieved!.matched)
        XCTAssertEqual(retrieved!.confidence, .high)
        XCTAssertEqual(retrieved!.matchScore, 85)
        XCTAssertEqual(retrieved!.link?.id, "test-123")
        XCTAssertEqual(retrieved!.link?.deepLinkValue, "/test/path")
    }

    func testCachedResult_CanStoreUnmatchedResult() {
        let result = DeepLinkResult(
            matched: false,
            confidence: nil,
            matchScore: nil,
            link: nil
        )

        storage.cachedResult = result
        let retrieved = storage.cachedResult

        XCTAssertNotNil(retrieved)
        XCTAssertFalse(retrieved!.matched)
        XCTAssertNil(retrieved!.confidence)
        XCTAssertNil(retrieved!.link)
    }

    func testCachedResult_CanBeSetToNil() {
        let result = DeepLinkResult(
            matched: true,
            confidence: .medium,
            matchScore: 50,
            link: nil
        )

        storage.cachedResult = result
        XCTAssertNotNil(storage.cachedResult)

        storage.cachedResult = nil
        XCTAssertNil(storage.cachedResult)
    }

    func testCachedResult_PersistsAcrossInstances() {
        let result = DeepLinkResult(
            matched: true,
            confidence: .high,
            matchScore: 90,
            link: DeepLinkResult.LinkData(
                id: "persist-test",
                name: nil,
                path: "/persist",
                shortenedPath: nil,
                url: nil,
                fullURL: nil,
                deepLinkValue: "/persist",
                iosDeferredDeepLinkingEnabled: nil,
                androidFallbackURL: nil,
                iosFallbackURL: nil,
                enableForcedRedirect: nil,
                socialTitle: nil,
                socialDescription: nil,
                socialImageURL: nil,
                clicks: nil
            )
        )

        storage.cachedResult = result

        // Create new storage instance with same defaults
        let newStorage = Storage(defaults: mockDefaults)
        let retrieved = newStorage.cachedResult

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.link?.id, "persist-test")
    }

    // MARK: - reset Tests

    func testReset_ClearsHasCheckedFlag() {
        storage.hasCheckedForDeferredDeepLink = true
        storage.reset()
        XCTAssertFalse(storage.hasCheckedForDeferredDeepLink)
    }

    func testReset_ClearsCachedResult() {
        storage.cachedResult = DeepLinkResult(
            matched: true,
            confidence: .high,
            matchScore: 85,
            link: nil
        )
        storage.reset()
        XCTAssertNil(storage.cachedResult)
    }

    func testReset_ClearsBothValues() {
        storage.hasCheckedForDeferredDeepLink = true
        storage.cachedResult = DeepLinkResult(
            matched: true,
            confidence: .medium,
            matchScore: 60,
            link: nil
        )

        storage.reset()

        XCTAssertFalse(storage.hasCheckedForDeferredDeepLink)
        XCTAssertNil(storage.cachedResult)
    }

    // MARK: - Edge Cases

    func testCachedResult_HandlesFullLinkData() {
        let link = DeepLinkResult.LinkData(
            id: "full-data",
            name: "Complete Link",
            path: "/complete/path",
            shortenedPath: "short123",
            url: URL(string: "https://example.com/complete?param=value"),
            fullURL: URL(string: "https://app.dynalinks.app/short123"),
            deepLinkValue: "/complete/path",
            iosDeferredDeepLinkingEnabled: true,
            androidFallbackURL: URL(string: "https://play.google.com/store/apps/details?id=com.example"),
            iosFallbackURL: URL(string: "https://apps.apple.com/app/id123456"),
            enableForcedRedirect: true,
            socialTitle: "Social Title",
            socialDescription: "Social Description",
            socialImageURL: URL(string: "https://example.com/image.jpg"),
            clicks: 1000
        )

        let result = DeepLinkResult(
            matched: true,
            confidence: .high,
            matchScore: 95,
            link: link
        )

        storage.cachedResult = result
        let retrieved = storage.cachedResult

        XCTAssertEqual(retrieved?.link?.shortenedPath, "short123")
        XCTAssertEqual(retrieved?.link?.androidFallbackURL, URL(string: "https://play.google.com/store/apps/details?id=com.example"))
        XCTAssertEqual(retrieved?.link?.iosFallbackURL, URL(string: "https://apps.apple.com/app/id123456"))
        XCTAssertEqual(retrieved?.link?.enableForcedRedirect, true)
        XCTAssertEqual(retrieved?.link?.socialTitle, "Social Title")
        XCTAssertEqual(retrieved?.link?.clicks, 1000)
    }
}

