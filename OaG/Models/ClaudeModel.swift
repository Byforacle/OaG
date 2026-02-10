import Foundation

enum ClaudeModel: String, CaseIterable, Codable, Identifiable, Sendable {
    case opus   = "claude-opus-4-20250514"
    case sonnet = "claude-sonnet-4-20250514"
    case haiku  = "claude-haiku-3-20250307"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .opus:   "Claude Opus"
        case .sonnet: "Claude Sonnet"
        case .haiku:  "Claude Haiku"
        }
    }

    var shortName: String {
        switch self {
        case .opus:   "Opus"
        case .sonnet: "Sonnet"
        case .haiku:  "Haiku"
        }
    }

    var maxOutputTokens: Int {
        switch self {
        case .opus:   16384
        case .sonnet: 16384
        case .haiku:  4096
        }
    }
}
