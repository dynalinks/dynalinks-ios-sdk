import Foundation

/// A URLProtocol subclass that intercepts requests and returns mock responses
///
/// Note: When URLSession uses URLProtocol, the request body is often passed via
/// `httpBodyStream` instead of `httpBody`. Use `URLRequest.bodyData` extension
/// to reliably access the body data.
///
/// See: https://github.com/swiftlang/swift-corelibs-foundation/issues/3199
final class MockURLProtocol: URLProtocol {
    /// Handler type for processing requests
    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data)

    /// The handler to use for the next request
    static var requestHandler: RequestHandler?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: MockError.noHandler)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // Nothing to do
    }
}

enum MockError: Error {
    case noHandler
}

// MARK: - Test Helpers

extension MockURLProtocol {
    /// Create a mock URLSession configured to use this protocol
    static func mockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    /// Set up a successful response with JSON data
    static func mockSuccess(json: String, statusCode: Int = 200) {
        requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, json.data(using: .utf8)!)
        }
    }

    /// Set up an error response
    static func mockError(statusCode: Int, message: String? = nil) {
        requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            let body: String
            if let message = message {
                body = "{\"error\": \"\(message)\"}"
            } else {
                body = "{}"
            }
            return (response, body.data(using: .utf8)!)
        }
    }

    /// Set up a network error
    static func mockNetworkError(_ error: Error) {
        requestHandler = { _ in
            throw error
        }
    }

    /// Reset the handler
    static func reset() {
        requestHandler = nil
    }
}

// MARK: - URLRequest Body Extension

extension URLRequest {
    /// Get the body data from either httpBody or httpBodyStream
    ///
    /// URLSession may use httpBodyStream instead of httpBody when processing
    /// requests through URLProtocol. This property handles both cases.
    var bodyData: Data? {
        if let httpBody = httpBody {
            return httpBody
        }

        guard let stream = httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }

        return data.isEmpty ? nil : data
    }
}
