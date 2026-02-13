import Foundation

struct ToolDefinition: Encodable, Sendable {
    let name: String
    let description: String
    let inputSchema: JSONValue

    enum CodingKeys: String, CodingKey {
        case name, description
        case inputSchema = "input_schema"
    }
}

enum ToolChoice: Encodable, Sendable {
    case auto
    case any
    case tool(name: String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .auto:
            try container.encode(["type": "auto"])
        case .any:
            try container.encode(["type": "any"])
        case .tool(let name):
            try container.encode(["type": "tool", "name": name])
        }
    }
}
