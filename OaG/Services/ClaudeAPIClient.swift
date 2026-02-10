import Foundation

final class ClaudeAPIClient: Sendable {
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession

    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        self.session = URLSession(configuration: config)
    }

    func streamMessage(_ request: MessagesRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached { [baseURL, apiKey, session] in
                do {
                    let urlRequest = try Self.buildRequest(
                        baseURL: baseURL,
                        apiKey: apiKey,
                        body: request
                    )
                    let (bytes, response) = try await session.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OaGError.invalidResponse
                    }

                    if httpResponse.statusCode != 200 {
                        var body = ""
                        for try await line in bytes.lines {
                            body += line
                        }
                        if httpResponse.statusCode == 502 {
                            throw OaGError.proxyError
                        }
                        throw OaGError.httpError(
                            statusCode: httpResponse.statusCode,
                            message: body
                        )
                    }

                    var parser = SSEStreamParser()
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        if let event = parser.processLine(line) {
                            continuation.yield(event)
                            if case .messageStop = event { break }
                            if case .error = event { break }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private static let maxRequestBodySize = 4_000_000

    private static func buildRequest(
        baseURL: String,
        apiKey: String,
        body: MessagesRequest
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/v1/messages") else {
            throw OaGError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        let encoded = try JSONEncoder().encode(body)
        if encoded.count > maxRequestBodySize {
            throw OaGError.requestTooLarge(encoded.count)
        }
        request.httpBody = encoded
        return request
    }
}
