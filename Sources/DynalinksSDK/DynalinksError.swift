import Foundation

/// Errors that can occur when using the Dynalinks SDK
public enum DynalinksError: Error, LocalizedError, Equatable {

    // MARK: - Configuration Errors

    /// SDK has not been configured. Call `Dynalinks.configure()` first.
    case notConfigured

    /// Invalid API key format. Must be a valid UUID.
    case invalidAPIKey(String)

    // MARK: - Runtime Errors

    /// Deferred deep linking is not available on simulator.
    case simulator

    // MARK: - Network Errors

    /// Network request failed.
    case networkError(underlying: Error?)

    /// Server returned an invalid response.
    case invalidResponse

    /// Server returned an error status code.
    case serverError(statusCode: Int, message: String?)

    // MARK: - Match Errors

    /// No matching deferred deep link was found.
    case noMatch

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Dynalinks SDK not configured. Call Dynalinks.configure() first."
        case .invalidAPIKey(let message):
            return "Invalid API key: \(message)"
        case .simulator:
            return "Deferred deep linking not available on simulator."
        case .networkError(let underlying):
            if let error = underlying {
                return "Network request failed: \(error.localizedDescription)"
            }
            return "Network request failed."
        case .invalidResponse:
            return "Invalid response from server."
        case .noMatch:
            return "No matching deferred deep link found."
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error: \(statusCode)"
        }
    }

    // MARK: - Equatable

    public static func == (lhs: DynalinksError, rhs: DynalinksError) -> Bool {
        switch (lhs, rhs) {
        case (.notConfigured, .notConfigured),
             (.simulator, .simulator),
             (.networkError, .networkError),
             (.invalidResponse, .invalidResponse),
             (.noMatch, .noMatch):
            return true
        case (.invalidAPIKey(let lhsMsg), .invalidAPIKey(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.serverError(let lhsCode, let lhsMsg), .serverError(let rhsCode, let rhsMsg)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg
        default:
            return false
        }
    }
}
