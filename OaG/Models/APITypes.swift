import Foundation

// MARK: - Request Types

struct MessagesRequest: Encodable, Sendable {
    let model: String
    let maxTokens: Int
    let messages: [APIMessage]
    let stream: Bool
    let system: String?

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages, stream, system
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(maxTokens, forKey: .maxTokens)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)
        if let system, !system.isEmpty {
            try container.encode(system, forKey: .system)
        }
    }
}

struct APIMessage: Encodable, Sendable {
    let role: String
    let content: [APIContentBlock]
}

enum APIContentBlock: Encodable, Sendable {
    case text(String)
    case image(mediaType: String, data: String)

    private enum CodingKeys: String, CodingKey {
        case type, text, source
    }

    private enum SourceKeys: String, CodingKey {
        case type
        case mediaType = "media_type"
        case data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let mediaType, let data):
            try container.encode("image", forKey: .type)
            var source = container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source)
            try source.encode("base64", forKey: .type)
            try source.encode(mediaType, forKey: .mediaType)
            try source.encode(data, forKey: .data)
        }
    }
}

// MARK: - SSE Event Types

enum SSEEvent: Sendable {
    case messageStart(messageId: String, model: String, inputTokens: Int)
    case contentBlockDelta(index: Int, text: String)
    case messageDelta(stopReason: String?, outputTokens: Int)
    case messageStop
    case error(APIError)
    case ping
}

// MARK: - Response Types

struct APIError: Decodable, Sendable {
    let type: String
    let message: String
}

struct SSEMessageStart: Decodable {
    let message: SSEMessageInfo
}

struct SSEMessageInfo: Decodable {
    let id: String
    let model: String
    let usage: SSEUsage?
}

struct SSEContentBlockDelta: Decodable {
    let index: Int
    let delta: SSEDelta
}

struct SSEDelta: Decodable {
    let type: String?
    let text: String?
}

struct SSEMessageDelta: Decodable {
    let delta: SSEStopDelta
    let usage: SSEUsage?
}

struct SSEStopDelta: Decodable {
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case stopReason = "stop_reason"
    }
}

struct SSEUsage: Decodable {
    let inputTokens: Int?
    let outputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct SSEErrorWrapper: Decodable {
    let error: APIError
}

// MARK: - App Error

enum OaGError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case apiError(String)
    case streamingFailed(String)
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "无效的服务器响应"
        case .httpError(let code, let message):
            "HTTP \(code): \(message)"
        case .apiError(let message):
            "API 错误: \(message)"
        case .streamingFailed(let message):
            "流式传输失败: \(message)"
        case .noAPIKey:
            "请先在设置中配置 API Key"
        }
    }
}
