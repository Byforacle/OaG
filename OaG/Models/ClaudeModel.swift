import Foundation

enum ClaudeModel: String, CaseIterable, Codable, Identifiable, Sendable {
    case opus   = "claude-opus-4-6"
    case sonnet = "claude-sonnet-4-5-20250929"
    case haiku  = "claude-haiku-4-5-20251001"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .opus:   "Claude Opus 4.6"
        case .sonnet: "Claude Sonnet 4.5"
        case .haiku:  "Claude Haiku 4.5"
        }
    }

    var shortName: String {
        switch self {
        case .opus:   "Opus 4.6"
        case .sonnet: "Sonnet 4.5"
        case .haiku:  "Haiku 4.5"
        }
    }

    var maxOutputTokens: Int {
        switch self {
        case .opus:   16384
        case .sonnet: 16384
        case .haiku:  8192
        }
    }

    static func fromLegacyIdentifier(_ identifier: String) -> ClaudeModel? {
        if let model = ClaudeModel(rawValue: identifier) {
            return model
        }
        switch identifier {
        case "claude-opus-4-20250514":
            return .opus
        case "claude-sonnet-4-20250514":
            return .sonnet
        case "claude-haiku-3-20250307", "claude-3-haiku-20240307":
            return .haiku
        default:
            if identifier.contains("opus")   { return .opus }
            if identifier.contains("sonnet") { return .sonnet }
            if identifier.contains("haiku")  { return .haiku }
            return nil
        }
    }
}
