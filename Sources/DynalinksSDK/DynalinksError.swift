import Foundation

/// Errors that can occur when using the Dynalinks SDK
public enum DynalinksError: Error, LocalizedError, Equatable {
    public static func == (lhs: DynalinksError, rhs: DynalinksError) -> Bool {
        switch (lhs, rhs) {
        case (.notConfigured, .notConfigured):
            return true
        case (.invalidAPIKey(let lhsMsg), .invalidAPIKey(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.alreadyChecked, .alreadyChecked):
            return true
        case (.simulator, .simulator):
            return true
        case (.networkError, .networkError):
            return true  // Don't compare underlying errors
        case (.invalidResponse, .invalidResponse):
            return true
        case (.noMatch, .noMatch):
            return true
        case (.serverError(let lhsCode, let lhsMsg), .serverError(let rhsCode, let rhsMsg)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg
        default:
            return false
        }
    }
    /// SDK has not been configured. Call `Dynalinks.configure()` first.
    case notConfigured

    /// Invalid API key format. Must be a valid UUID.
    case invalidAPIKey(String)

    /// Deferred deep link check has already been performed for this installation.
    case alreadyChecked

    /// Deferred deep linking is not available on simulator.
    case simulator

    /// Network request failed.
    case networkError(underlying: Error?)

    /// Server returned an invalid response.
    case invalidResponse

    /// No matching deferred deep link was found.
    case noMatch

    /// Server returned an error status code.
    case serverError(statusCode: Int, message: String?)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Dynalinks SDK not configured. Call Dynalinks.configure() first."
        case .invalidAPIKey(let message):
            return "Invalid API key: \(message)"
        case .alreadyChecked:
            return "Deferred deep link already checked for this installation."
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
}
