import Foundation

/// Main entry point for Dynalinks SDK
///
/// Use this class to configure the SDK and check for deferred deep links.
///
/// ## Setup
///
/// Configure the SDK as early as possible in your app's lifecycle:
///
/// ```swift
/// Dynalinks.configure(clientAPIKey: "your-client-api-key")
/// ```
///
/// ## Check for Deferred Deep Links
///
/// Call this on first app launch to check if the user came from a Dynalinks link:
///
/// ```swift
/// Task {
///     do {
///         let result = try await Dynalinks.checkForDeferredDeepLink()
///         if result.matched, let link = result.link {
///             // Navigate to link.deepLinkValue
///         }
///     } catch {
///         // No deferred deep link found
///     }
/// }
/// ```
public final class Dynalinks: @unchecked Sendable {
    // MARK: - Version

    /// The current version of the Dynalinks SDK
    public static let version = "1.0.1"

    // MARK: - Singleton

    /// Lock for thread-safe singleton initialization
    private static let configurationLock = NSLock()
    private static var shared: Dynalinks?

    // MARK: - Properties

    private let apiClient: APIClient
    private let storage: Storage
    private let allowSimulator: Bool

    // MARK: - Initialization

    private init(
        clientAPIKey: String,
        baseURL: URL,
        logLevel: DynalinksLogLevel,
        allowSimulator: Bool
    ) {
        self.apiClient = APIClient(baseURL: baseURL, clientAPIKey: clientAPIKey)
        self.storage = Storage()
        self.allowSimulator = allowSimulator
        DynalinksLogger.logLevel = logLevel
    }

    /// Internal initializer for testing with dependency injection
    internal init(
        apiClient: APIClient,
        storage: Storage,
        allowSimulator: Bool
    ) {
        self.apiClient = apiClient
        self.storage = storage
        self.allowSimulator = allowSimulator
    }

    // MARK: - Public Configuration

    /// Configure the Dynalinks SDK
    ///
    /// Call this method as early as possible in your app's lifecycle,
    /// typically in `application(_:didFinishLaunchingWithOptions:)` or your App's `init`.
    ///
    /// - Parameters:
    ///   - clientAPIKey: Your project's client API key from the Dynalinks console
    ///   - baseURL: API base URL (defaults to production)
    ///   - logLevel: Logging verbosity (defaults to `.error` for release, `.debug` for development)
    ///   - allowSimulator: Allow deferred deep link checks on simulator (defaults to `false`)
    /// - Throws: `DynalinksError.invalidAPIKey` if the API key is empty
    public static func configure(
        clientAPIKey: String,
        baseURL: URL = URL(string: "https://dynalinks.app/api/v1")!,
        logLevel: DynalinksLogLevel = {
            #if DEBUG
            return .debug
            #else
            return .error
            #endif
        }(),
        allowSimulator: Bool = false
    ) throws {
        // Validate API key before acquiring lock
        guard !clientAPIKey.isEmpty else {
            DynalinksLogger.error("Invalid API key: empty string")
            throw DynalinksError.invalidAPIKey("Client API key cannot be empty")
        }

        // Thread-safe singleton initialization
        configurationLock.lock()
        defer { configurationLock.unlock() }

        // Skip if already configured (prevents double initialization in SwiftUI)
        if shared != nil {
            DynalinksLogger.debug("SDK already configured, skipping")
            return
        }

        shared = Dynalinks(
            clientAPIKey: clientAPIKey,
            baseURL: baseURL,
            logLevel: logLevel,
            allowSimulator: allowSimulator
        )
        DynalinksLogger.info("Dynalinks SDK configured")
    }

    // MARK: - Public API

    /// Check for a deferred deep link
    ///
    /// This method should be called once on first app launch. It will:
    /// 1. Collect device fingerprint
    /// 2. Send it to the Dynalinks server for matching
    /// 3. Return the matched link if found
    ///
    /// The SDK automatically prevents duplicate checks - subsequent calls
    /// will return the cached result or throw `.alreadyChecked`.
    ///
    /// - Returns: A `DeepLinkResult` containing the matched link data
    /// - Throws: `DynalinksError` if the check fails or no match is found
    public static func checkForDeferredDeepLink() async throws -> DeepLinkResult {
        guard let sdk = shared else {
            DynalinksLogger.error("SDK not configured")
            throw DynalinksError.notConfigured
        }
        return try await sdk.performCheck()
    }

    /// Check for a deferred deep link with completion handler
    ///
    /// Convenience method for non-async contexts.
    ///
    /// - Parameter completion: Callback with the result or error
    public static func checkForDeferredDeepLink(
        completion: @escaping (Result<DeepLinkResult, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await checkForDeferredDeepLink()
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Handle a Universal Link that opened the app
    ///
    /// Call this when your app receives a Universal Link. The SDK will:
    /// 1. Resolve the link and return its data
    /// 2. Record the click for analytics
    /// 3. Skip any subsequent deferred deep link check
    ///
    /// Example usage in SceneDelegate:
    /// ```swift
    /// func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    ///     guard let url = userActivity.webpageURL else { return }
    ///     Task {
    ///         let result = try await Dynalinks.handleUniversalLink(url: url)
    ///         if result.matched, let link = result.link {
    ///             // Navigate to link.deepLinkValue
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter url: The Universal Link URL that opened the app
    /// - Returns: A `DeepLinkResult` with the resolved link data
    /// - Throws: `DynalinksError` if the SDK is not configured or the request fails
    public static func handleUniversalLink(url: URL) async throws -> DeepLinkResult {
        guard let sdk = shared else {
            DynalinksLogger.error("SDK not configured")
            throw DynalinksError.notConfigured
        }
        return try await sdk.resolveUniversalLink(url: url)
    }

    /// Handle a Universal Link with completion handler
    ///
    /// Convenience method for non-async contexts.
    ///
    /// - Parameters:
    ///   - url: The Universal Link URL that opened the app
    ///   - completion: Callback with the result or error
    public static func handleUniversalLink(
        url: URL,
        completion: @escaping (Result<DeepLinkResult, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await handleUniversalLink(url: url)
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Reset the SDK state
    ///
    /// This clears the cached result and allows `checkForDeferredDeepLink`
    /// to be called again. Useful for testing.
    ///
    /// - Warning: Do not use in production. This is intended for testing only.
    public static func reset() {
        shared?.storage.reset()
        DynalinksLogger.info("SDK state reset")
    }

    /// Internal method to set the shared instance for testing
    internal static func setShared(_ sdk: Dynalinks?) {
        shared = sdk
    }

    // MARK: - Private Implementation

    private func performCheck() async throws -> DeepLinkResult {
        // Return cached result or no-match if already checked
        if storage.hasCheckedForDeferredDeepLink {
            DynalinksLogger.debug("Already checked for deferred deep link")
            if let cached = storage.cachedResult {
                DynalinksLogger.info("Returning cached result")
                return cached
            }
            DynalinksLogger.info("Previously checked, no match found")
            return DeepLinkResult(matched: false, confidence: nil, matchScore: nil, link: nil)
        }

        // Skip on simulator unless explicitly allowed
        #if targetEnvironment(simulator)
        if !allowSimulator {
            DynalinksLogger.info("Skipping deferred deep link check on simulator")
            storage.hasCheckedForDeferredDeepLink = true
            throw DynalinksError.simulator
        }
        DynalinksLogger.warning("Running on simulator with allowSimulator=true")
        #endif

        // Collect fingerprint
        let fingerprint = DeviceFingerprint.collect()
        DynalinksLogger.debug("Collected fingerprint: \(fingerprint.deviceModel), \(fingerprint.osVersion)")

        // Make API request
        let result = try await apiClient.matchFingerprint(fingerprint)

        // Mark as checked
        storage.hasCheckedForDeferredDeepLink = true

        // Cache successful match
        if result.matched {
            storage.cachedResult = result
            let confidence = result.confidence?.rawValue ?? "unknown"
            DynalinksLogger.info("Match found: confidence=\(confidence), score=\(result.matchScore ?? 0)")
        } else {
            DynalinksLogger.info("No match found")
        }

        return result
    }

    private func resolveUniversalLink(url: URL) async throws -> DeepLinkResult {
        DynalinksLogger.debug("Resolving Universal Link: \(url)")

        // Mark as checked to skip deferred deep link check
        storage.hasCheckedForDeferredDeepLink = true

        // Make API request to attribute the link
        let result = try await apiClient.attributeLink(url: url)

        // Cache successful match
        if result.matched {
            storage.cachedResult = result
            DynalinksLogger.info("Universal Link resolved: \(result.link?.path ?? "unknown")")
        } else {
            DynalinksLogger.info("Universal Link not matched")
        }

        return result
    }
}
