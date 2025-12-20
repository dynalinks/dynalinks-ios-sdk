import Foundation

/// API client for Dynalinks server communication
final class APIClient {
    private let baseURL: URL
    private let clientAPIKey: String
    private let session: URLSession

    init(baseURL: URL, clientAPIKey: String, session: URLSession? = nil) {
        self.baseURL = baseURL
        self.clientAPIKey = clientAPIKey

        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10
            config.timeoutIntervalForResource = 30
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
            Logger.error("Failed to encode fingerprint: \(error)")
            throw DynalinksError.invalidResponse
        }

        Logger.debug("Sending match request to \(url)")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            Logger.error("Network request failed: \(error)")
            throw DynalinksError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.error("Invalid response type")
            throw DynalinksError.invalidResponse
        }

        Logger.debug("Response status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200...299:
            return try decodeResponse(data)
        case 401:
            Logger.error("Unauthorized - check client API key")
            throw DynalinksError.serverError(statusCode: 401, message: "Invalid client API key")
        case 429:
            Logger.warning("Rate limited")
            throw DynalinksError.serverError(statusCode: 429, message: "Rate limit exceeded")
        default:
            let message = try? decodeErrorMessage(data)
            Logger.error("Server error: \(httpResponse.statusCode) - \(message ?? "unknown")")
            throw DynalinksError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func decodeResponse(_ data: Data) throws -> DeepLinkResult {
        do {
            let result = try JSONDecoder().decode(DeepLinkResult.self, from: data)
            Logger.debug("Decoded result: matched=\(result.matched)")
            return result
        } catch {
            Logger.error("Failed to decode response: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.debug("Response body: \(responseString)")
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
