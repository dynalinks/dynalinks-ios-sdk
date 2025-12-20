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
public final class Dynalinks {
    // MARK: - Version

    /// The current version of the Dynalinks SDK
    public static let version = "1.0.0"

    // MARK: - Singleton

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
        Logger.logLevel = logLevel
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
    ///   - clientAPIKey: Your project's client API key from the Dynalinks console (must be a valid UUID)
    ///   - baseURL: API base URL (defaults to production)
    ///   - logLevel: Logging verbosity (defaults to `.error` for release, `.debug` for development)
    ///   - allowSimulator: Allow deferred deep link checks on simulator (defaults to `false`)
    /// - Throws: `DynalinksError.invalidAPIKey` if the API key is not a valid UUID
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
        // Validate API key format
        guard UUID(uuidString: clientAPIKey) != nil else {
            Logger.error("Invalid API key format: \(clientAPIKey)")
            throw DynalinksError.invalidAPIKey("Client API key must be a valid UUID")
        }

        shared = Dynalinks(
            clientAPIKey: clientAPIKey,
            baseURL: baseURL,
            logLevel: logLevel,
            allowSimulator: allowSimulator
        )
        Logger.info("Dynalinks SDK configured")
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
            Logger.error("SDK not configured")
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

    /// Reset the SDK state
    ///
    /// This clears the cached result and allows `checkForDeferredDeepLink`
    /// to be called again. Useful for testing.
    ///
    /// - Warning: Do not use in production. This is intended for testing only.
    public static func reset() {
        shared?.storage.reset()
        Logger.info("SDK state reset")
    }

    /// Internal method to set the shared instance for testing
    internal static func setShared(_ sdk: Dynalinks?) {
        shared = sdk
    }

    // MARK: - Private Implementation

    private func performCheck() async throws -> DeepLinkResult {
        // Return cached result if already checked
        if storage.hasCheckedForDeferredDeepLink {
            Logger.debug("Already checked for deferred deep link")
            if let cached = storage.cachedResult {
                Logger.info("Returning cached result")
                return cached
            }
            throw DynalinksError.alreadyChecked
        }

        // Skip on simulator unless explicitly allowed
        #if targetEnvironment(simulator)
        if !allowSimulator {
            Logger.info("Skipping deferred deep link check on simulator")
            storage.hasCheckedForDeferredDeepLink = true
            throw DynalinksError.simulator
        }
        Logger.warning("Running on simulator with allowSimulator=true")
        #endif

        // Collect fingerprint
        let fingerprint = DeviceFingerprint.collect()
        Logger.debug("Collected fingerprint: \(fingerprint.deviceModel), \(fingerprint.osVersion)")

        // Make API request
        let result = try await apiClient.matchFingerprint(fingerprint)

        // Mark as checked
        storage.hasCheckedForDeferredDeepLink = true

        // Cache successful match
        if result.matched {
            storage.cachedResult = result
            let confidence = result.confidence?.rawValue ?? "unknown"
            Logger.info("Match found: confidence=\(confidence), score=\(result.matchScore ?? 0)")
        } else {
            Logger.info("No match found")
        }

        return result
    }
}
