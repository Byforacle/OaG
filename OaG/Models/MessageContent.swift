import Foundation

enum ContentBlock: Codable, Hashable, Sendable {
    case text(String)
    case image(mediaType: String, base64Data: String)
    case toolUse(id: String, name: String, input: String)
    case toolResult(toolUseId: String, content: String, isError: Bool)

    private enum BlockType: String, Codable {
        case text
        case image
        case toolUse = "tool_use"
        case toolResult = "tool_result"
    }

    private enum CodingKeys: String, CodingKey {
        case type, text, source
        // tool_use keys
        case id, name, input
        // tool_result keys
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
            try container.encode(BlockType.text, forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let mediaType, let base64Data):
            try container.encode(BlockType.image, forKey: .type)
            var source = container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source)
            try source.encode("base64", forKey: .type)
            try source.encode(mediaType, forKey: .mediaType)
            try source.encode(base64Data, forKey: .data)
        case .toolUse(let id, let name, let input):
            try container.encode(BlockType.toolUse, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(input, forKey: .input)
        case .toolResult(let toolUseId, let content, let isError):
            try container.encode(BlockType.toolResult, forKey: .type)
            try container.encode(toolUseId, forKey: .toolUseId)
            try container.encode(content, forKey: .content)
            try container.encode(isError, forKey: .isError)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Gracefully handle unknown block types from future versions
        let typeString = try container.decode(String.self, forKey: .type)
        guard let blockType = BlockType(rawValue: typeString) else {
            self = .text("[unsupported block: \(typeString)]")
            return
        }
        switch blockType {
        case .text:
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case .image:
            let source = try container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source)
            let mediaType = try source.decode(String.self, forKey: .mediaType)
            let data = try source.decode(String.self, forKey: .data)
            self = .image(mediaType: mediaType, base64Data: data)
        case .toolUse:
            let id = try container.decode(String.self, forKey: .id)
            let name = try container.decode(String.self, forKey: .name)
            let input = try container.decode(String.self, forKey: .input)
            self = .toolUse(id: id, name: name, input: input)
        case .toolResult:
            let toolUseId = try container.decode(String.self, forKey: .toolUseId)
            let content = try container.decode(String.self, forKey: .content)
            let isError = try container.decodeIfPresent(Bool.self, forKey: .isError) ?? false
            self = .toolResult(toolUseId: toolUseId, content: content, isError: isError)
        }
    }

    /// Extract text content for display purposes.
    var textContent: String? {
        switch self {
        case .text(let t): return t
        case .toolUse(_, let name, _): return "[Tool: \(name)]"
        case .toolResult(_, let content, _): return content
        case .image: return nil
        }
    }
}
