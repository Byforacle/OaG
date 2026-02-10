import Foundation

enum ContentBlock: Codable, Hashable, Sendable {
    case text(String)
    case image(mediaType: String, base64Data: String)

    private enum BlockType: String, Codable {
        case text
        case image
    }

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
            try container.encode(BlockType.text, forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let mediaType, let base64Data):
            try container.encode(BlockType.image, forKey: .type)
            var source = container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source)
            try source.encode("base64", forKey: .type)
            try source.encode(mediaType, forKey: .mediaType)
            try source.encode(base64Data, forKey: .data)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BlockType.self, forKey: .type)
        switch type {
        case .text:
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case .image:
            let source = try container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source)
            let mediaType = try source.decode(String.self, forKey: .mediaType)
            let data = try source.decode(String.self, forKey: .data)
            self = .image(mediaType: mediaType, base64Data: data)
        }
    }
}
