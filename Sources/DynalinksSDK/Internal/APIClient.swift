import Foundation

/// API client for Dynalinks server communication
final class APIClient {
    private let baseURL: URL
    private let clientAPIKey: String
    private let session: URLSession

    /// Maximum number of retry attempts for transient failures (0 = no retries)
    private let maxRetries: Int

    /// Base delay between retries (exponential backoff: 1s, 2s, 4s)
    private let baseRetryDelay: TimeInterval

    /// Creates an API client
    /// - Parameters:
    ///   - baseURL: API base URL
    ///   - clientAPIKey: Client API key for authentication
    ///   - session: URLSession to use (optional, for testing)
    ///   - maxRetries: Maximum retry attempts (default: 3, set to 0 for no retries)
    ///   - baseRetryDelay: Base delay between retries in seconds (default: 1.0)
    init(
        baseURL: URL,
        clientAPIKey: String,
        session: URLSession? = nil,
        maxRetries: Int = 3,
        baseRetryDelay: TimeInterval = 1.0
    ) {
        self.baseURL = baseURL
        self.clientAPIKey = clientAPIKey
        self.maxRetries = maxRetries
        self.baseRetryDelay = baseRetryDelay

        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10
            config.timeoutIntervalForResource = 30
            // Wait for connectivity instead of failing immediately
            config.waitsForConnectivity = true
            self.session = URLSession(configuration: config)
        }
    }

    /// Match fingerprint against stored web fingerprints
    func matchFingerprint(_ fingerprint: DeviceFingerprint) async throws -> DeepLinkResult {
        let url = baseURL.appendingPathComponent("fingerprints/match")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(clientAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DynalinksSDK-iOS/\(Dynalinks.version)", forHTTPHeaderField: "User-Agent")

        let body = FingerprintRequest(fingerprint: fingerprint)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            DynalinksLogger.error("Failed to encode fingerprint: \(error)")
            throw DynalinksError.invalidResponse
        }

        DynalinksLogger.debug("Sending match request to \(url)")

        return try await performRequestWithRetry(request)
    }

    /// Attribute a Universal Link URL to get link data
    func attributeLink(url: URL) async throws -> DeepLinkResult {
        let endpoint = baseURL.appendingPathComponent("links/attribute")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(clientAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DynalinksSDK-iOS/\(Dynalinks.version)", forHTTPHeaderField: "User-Agent")

        let body = ResolveLinkRequest(url: url.absoluteString, platform: "ios")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            DynalinksLogger.error("Failed to encode resolve request: \(error)")
            throw DynalinksError.invalidResponse
        }

        DynalinksLogger.debug("Sending resolve request to \(endpoint)")

        return try await performRequestWithRetry(request)
    }

    /// Performs HTTP request with exponential backoff retry for transient failures
    private func performRequestWithRetry(_ request: URLRequest) async throws -> DeepLinkResult {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    DynalinksLogger.error("Invalid response type")
                    throw DynalinksError.invalidResponse
                }

                DynalinksLogger.debug("Response status: \(httpResponse.statusCode) (attempt \(attempt + 1))")

                switch httpResponse.statusCode {
                case 200...299:
                    return try decodeResponse(data)

                // Client errors - don't retry
                case 400...499:
                    return try handleClientError(httpResponse.statusCode, data: data)

                // Server errors - retry with backoff
                case 500...599:
                    let message = try? decodeErrorMessage(data)
                    let error = DynalinksError.serverError(statusCode: httpResponse.statusCode, message: message)
                    lastError = error

                    if attempt < maxRetries {
                        let delay = baseRetryDelay * pow(2.0, Double(attempt))
                        DynalinksLogger.warning("Server error \(httpResponse.statusCode), retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries + 1))")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }

                    DynalinksLogger.error("Server error after \(maxRetries + 1) attempts: \(httpResponse.statusCode)")
                    throw error

                default:
                    let message = try? decodeErrorMessage(data)
                    throw DynalinksError.serverError(statusCode: httpResponse.statusCode, message: message)
                }
            } catch let error as DynalinksError {
                // Rethrow DynalinksError directly (no retry for client errors)
                throw error
            } catch {
                // Network errors - retry with backoff
                lastError = error

                if attempt < maxRetries {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    DynalinksLogger.warning("Network error, retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries + 1)): \(error.localizedDescription)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

                DynalinksLogger.error("Network request failed after \(maxRetries + 1) attempts: \(error)")
                throw DynalinksError.networkError(underlying: error)
            }
        }

        // Should not reach here, but handle just in case
        throw lastError ?? DynalinksError.networkError(underlying: NSError(domain: "DynalinksSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
    }

    /// Handle 4xx client errors (no retry)
    private func handleClientError(_ statusCode: Int, data: Data) throws -> DeepLinkResult {
        switch statusCode {
        case 401:
            DynalinksLogger.error("Unauthorized - check client API key")
            throw DynalinksError.serverError(statusCode: 401, message: "Invalid client API key")
        case 429:
            DynalinksLogger.warning("Rate limited")
            throw DynalinksError.serverError(statusCode: 429, message: "Rate limit exceeded")
        default:
            let message = try? decodeErrorMessage(data)
            DynalinksLogger.error("Client error: \(statusCode) - \(message ?? "unknown")")
            throw DynalinksError.serverError(statusCode: statusCode, message: message)
        }
    }

    private func decodeResponse(_ data: Data) throws -> DeepLinkResult {
        do {
            let result = try JSONDecoder().decode(DeepLinkResult.self, from: data)
            DynalinksLogger.debug("Decoded result: matched=\(result.matched)")
            return result
        } catch {
            DynalinksLogger.error("Failed to decode response: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                DynalinksLogger.debug("Response body: \(responseString)")
            }
            throw DynalinksError.invalidResponse
        }
    }

    private func decodeErrorMessage(_ data: Data) throws -> String? {
        struct ErrorResponse: Decodable {
            let error: String?
            let message: String?
        }

        let response = try JSONDecoder().decode(ErrorResponse.self, from: data)
        return response.error ?? response.message
    }
}

// MARK: - Request Types

private struct FingerprintRequest: Encodable {
    let fingerprint: DeviceFingerprint
}

private struct ResolveLinkRequest: Encodable {
    let url: String
    let platform: String
}
