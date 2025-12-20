import XCTest
@testable import DynalinksSDK

final class DeepLinkResultTests: XCTestCase {

    func testDecodeMatchedResult() throws {
        let json = """
        {
            "matched": true,
            "confidence": "high",
            "match_score": 85,
            "link": {
                "id": "abc-123",
                "name": "Product Link",
                "path": "/product/shoes",
                "url": "https://example.com/product/shoes?ref=campaign",
                "full_url": "https://app.dynalinks.app/product/shoes",
                "deep_link_value": "/product/shoes",
                "ios_deferred_deep_linking_enabled": true
            }
        }
        """

        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(DeepLinkResult.self, from: data)

        XCTAssertTrue(result.matched)
        XCTAssertEqual(result.confidence, .high)
        XCTAssertEqual(result.matchScore, 85)
        XCTAssertNotNil(result.link)
        XCTAssertEqual(result.link?.id, "abc-123")
        XCTAssertEqual(result.link?.name, "Product Link")
        XCTAssertEqual(result.link?.path, "/product/shoes")
        XCTAssertEqual(result.link?.url, URL(string: "https://example.com/product/shoes?ref=campaign"))
        XCTAssertEqual(result.link?.fullURL, URL(string: "https://app.dynalinks.app/product/shoes"))
        XCTAssertEqual(result.link?.deepLinkValue, "/product/shoes")
        XCTAssertEqual(result.link?.iosDeferredDeepLinkingEnabled, true)

        // Query params can be parsed from URL using URLComponents
        let components = URLComponents(url: result.link!.url!, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.queryItems?.first(where: { $0.name == "ref" })?.value, "campaign")
    }

    func testDecodeUnmatchedResult() throws {
        let json = """
        {
            "matched": false
        }
        """

        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(DeepLinkResult.self, from: data)

        XCTAssertFalse(result.matched)
        XCTAssertNil(result.confidence)
        XCTAssertNil(result.matchScore)
        XCTAssertNil(result.link)
    }

    func testDecodeMediumConfidence() throws {
        let json = """
        {
            "matched": true,
            "confidence": "medium",
            "match_score": 45,
            "link": {
                "id": "xyz-789",
                "path": "/promo"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(DeepLinkResult.self, from: data)

        XCTAssertTrue(result.matched)
        XCTAssertEqual(result.confidence, .medium)
        XCTAssertEqual(result.matchScore, 45)
    }

    func testResultEquality() {
        let result1 = DeepLinkResult(
            matched: true,
            confidence: .high,
            matchScore: 85,
            link: nil
        )

        let result2 = DeepLinkResult(
            matched: true,
            confidence: .high,
            matchScore: 85,
            link: nil
        )

        XCTAssertEqual(result1, result2)
    }
}
