import Foundation

/// Result of a deferred deep link check
public struct DeepLinkResult: Codable, Equatable {
    /// Whether a matching link was found
    public let matched: Bool

    /// Confidence level of the match
    public let confidence: Confidence?

    /// Match score (0-100)
    public let matchScore: Int?

    /// Link data if matched
    public let link: LinkData?

    /// Initialize a deep link result
    public init(matched: Bool, confidence: Confidence? = nil, matchScore: Int? = nil, link: LinkData? = nil) {
        self.matched = matched
        self.confidence = confidence
        self.matchScore = matchScore
        self.link = link
    }

    public enum Confidence: String, Codable, Equatable {
        case high
        case medium
        case low
    }

    public struct LinkData: Codable, Equatable {
        /// Unique identifier for the link (uuid)
        public let id: String

        /// Link name
        public let name: String?

        /// Path component of the link
        public let path: String?

        /// Shortened path for the link
        public let shortenedPath: String?

        /// Original URL the link points to
        public let url: URL?

        /// Full Dynalinks URL
        public let fullURL: URL?

        /// Deep link value for routing in app
        public let deepLinkValue: String?

        /// Whether iOS deferred deep linking is enabled
        public let iosDeferredDeepLinkingEnabled: Bool?

        /// Android fallback URL
        public let androidFallbackURL: URL?

        /// iOS fallback URL
        public let iosFallbackURL: URL?

        /// Whether forced redirect is enabled
        public let enableForcedRedirect: Bool?

        /// Social sharing title
        public let socialTitle: String?

        /// Social sharing description
        public let socialDescription: String?

        /// Social sharing image URL
        public let socialImageURL: URL?

        /// Number of clicks
        public let clicks: Int?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case path
            case shortenedPath = "shortened_path"
            case url
            case fullURL = "full_url"
            case deepLinkValue = "deep_link_value"
            case iosDeferredDeepLinkingEnabled = "ios_deferred_deep_linking_enabled"
            case androidFallbackURL = "android_fallback_url"
            case iosFallbackURL = "ios_fallback_url"
            case enableForcedRedirect = "enable_forced_redirect"
            case socialTitle = "social_title"
            case socialDescription = "social_description"
            case socialImageURL = "social_image_url"
            case clicks
        }

        /// Initialize link data
        public init(
            id: String,
            name: String? = nil,
            path: String? = nil,
            shortenedPath: String? = nil,
            url: URL? = nil,
            fullURL: URL? = nil,
            deepLinkValue: String? = nil,
            iosDeferredDeepLinkingEnabled: Bool? = nil,
            androidFallbackURL: URL? = nil,
            iosFallbackURL: URL? = nil,
            enableForcedRedirect: Bool? = nil,
            socialTitle: String? = nil,
            socialDescription: String? = nil,
            socialImageURL: URL? = nil,
            clicks: Int? = nil
        ) {
            self.id = id
            self.name = name
            self.path = path
            self.shortenedPath = shortenedPath
            self.url = url
            self.fullURL = fullURL
            self.deepLinkValue = deepLinkValue
            self.iosDeferredDeepLinkingEnabled = iosDeferredDeepLinkingEnabled
            self.androidFallbackURL = androidFallbackURL
            self.iosFallbackURL = iosFallbackURL
            self.enableForcedRedirect = enableForcedRedirect
            self.socialTitle = socialTitle
            self.socialDescription = socialDescription
            self.socialImageURL = socialImageURL
            self.clicks = clicks
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            path = try container.decodeIfPresent(String.self, forKey: .path)
            shortenedPath = try container.decodeIfPresent(String.self, forKey: .shortenedPath)
            deepLinkValue = try container.decodeIfPresent(String.self, forKey: .deepLinkValue)
            iosDeferredDeepLinkingEnabled = try container.decodeIfPresent(
                Bool.self,
                forKey: .iosDeferredDeepLinkingEnabled
            )
            enableForcedRedirect = try container.decodeIfPresent(Bool.self, forKey: .enableForcedRedirect)
            clicks = try container.decodeIfPresent(Int.self, forKey: .clicks)

            // Decode URL strings to URL objects
            url = Self.decodeURL(from: container, forKey: .url)
            fullURL = Self.decodeURL(from: container, forKey: .fullURL)
            androidFallbackURL = Self.decodeURL(from: container, forKey: .androidFallbackURL)
            iosFallbackURL = Self.decodeURL(from: container, forKey: .iosFallbackURL)
            socialImageURL = Self.decodeURL(from: container, forKey: .socialImageURL)
            socialTitle = try container.decodeIfPresent(String.self, forKey: .socialTitle)
            socialDescription = try container.decodeIfPresent(String.self, forKey: .socialDescription)
        }

        private static func decodeURL(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) -> URL? {
            guard let urlString = try? container.decodeIfPresent(String.self, forKey: key),
                  let url = URL(string: urlString) else {
                return nil
            }
            return url
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(path, forKey: .path)
            try container.encodeIfPresent(shortenedPath, forKey: .shortenedPath)
            try container.encodeIfPresent(url?.absoluteString, forKey: .url)
            try container.encodeIfPresent(fullURL?.absoluteString, forKey: .fullURL)
            try container.encodeIfPresent(deepLinkValue, forKey: .deepLinkValue)
            try container.encodeIfPresent(iosDeferredDeepLinkingEnabled, forKey: .iosDeferredDeepLinkingEnabled)
            try container.encodeIfPresent(androidFallbackURL?.absoluteString, forKey: .androidFallbackURL)
            try container.encodeIfPresent(iosFallbackURL?.absoluteString, forKey: .iosFallbackURL)
            try container.encodeIfPresent(enableForcedRedirect, forKey: .enableForcedRedirect)
            try container.encodeIfPresent(socialTitle, forKey: .socialTitle)
            try container.encodeIfPresent(socialDescription, forKey: .socialDescription)
            try container.encodeIfPresent(socialImageURL?.absoluteString, forKey: .socialImageURL)
            try container.encodeIfPresent(clicks, forKey: .clicks)
        }
    }

    enum CodingKeys: String, CodingKey {
        case matched
        case confidence
        case matchScore = "match_score"
        case link
    }
}
