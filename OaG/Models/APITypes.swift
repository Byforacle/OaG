import Foundation

// MARK: - Request Types

struct MessagesRequest: Encodable, Sendable {
    let model: String
    let maxTokens: Int
    let messages: [APIMessage]
    let stream: Bool
    let system: String?
    let tools: [ToolDefinition]?
    let toolChoice: ToolChoice?

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages, stream, system, tools
        case toolChoice = "tool_choice"
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
        if let tools, !tools.isEmpty {
            try container.encode(tools, forKey: .tools)
        }
        if let toolChoice {
            try container.encode(toolChoice, forKey: .toolChoice)
        }
    }
}

struct APIMessage: Encodable, Sendable {
    let role: String
    let content: [APIContentBlock]
}

// MARK: - API Content Blocks

enum ToolResultContent: Encodable, Sendable {
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

enum APIContentBlock: Encodable, Sendable {
    case text(String)
    case image(mediaType: String, data: String)
    case toolUse(id: String, name: String, input: String)
    case toolResult(toolUseId: String, content: [ToolResultContent], isError: Bool)

    private enum CodingKeys: String, CodingKey {
        case type, text, source
        case id, name, input
        case toolUseId = "tool_use_id"
        case content
        case isError = "is_error"
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
        case .toolUse(let id, let name, let input):
            try container.encode("tool_use", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            // input is raw JSON string, encode as raw JSON
            if let jsonData = input.data(using: .utf8),
               let jsonObj = try? JSONSerialization.jsonObject(with: jsonData) {
                let rawData = try JSONSerialization.data(withJSONObject: jsonObj)
                let rawJSON = try JSONDecoder().decode(JSONValue.self, from: rawData)
                try container.encode(rawJSON, forKey: .input)
            } else {
                try container.encode(JSONValue.object([:]), forKey: .input)
            }
        case .toolResult(let toolUseId, let content, let isError):
            try container.encode("tool_result", forKey: .type)
            try container.encode(toolUseId, forKey: .toolUseId)
            try container.encode(content, forKey: .content)
            if isError {
                try container.encode(true, forKey: .isError)
            }
        }
    }
}

// MARK: - SSE Event Types

enum SSEEvent: Sendable {
    case messageStart(messageId: String, model: String, inputTokens: Int)
    case contentBlockStart(index: Int, type: String, id: String?, name: String?)
    case contentBlockDelta(index: Int, text: String)
    case inputJsonDelta(index: Int, partialJson: String)
    case contentBlockStop(index: Int)
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
    let partialJson: String?

    enum CodingKeys: String, CodingKey {
        case type, text
        case partialJson = "partial_json"
    }
}

struct SSEContentBlockStart: Decodable {
    let index: Int
    let contentBlock: SSEContentBlockInfo

    enum CodingKeys: String, CodingKey {
        case index
        case contentBlock = "content_block"
    }
}

struct SSEContentBlockInfo: Decodable {
    let type: String
    let id: String?
    let name: String?
}

struct SSEContentBlockStopEvent: Decodable {
    let index: Int
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
    case requestTooLarge(Int)
    case proxyError
    case maxIterationsReached

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
        case .requestTooLarge(let size):
            "请求体过大 (\(size / 1024)KB)，请减少图片数量后重试"
        case .proxyError:
            "代理服务暂时不可用，可能是请求内容过大。请减少图片数量或稍后重试"
        case .maxIterationsReached:
            "Agent 已达到最大迭代次数限制"
        }
    }
}
