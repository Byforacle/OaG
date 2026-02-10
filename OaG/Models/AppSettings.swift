import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var baseURL: String
    var defaultModelIdentifier: String
    var maxTokens: Int
    var defaultSystemPrompt: String
    var sendWithReturn: Bool

    init() {
        self.id = UUID()
        self.baseURL = "https://code.aipor.cc"
        self.defaultModelIdentifier = ClaudeModel.opus.rawValue
        self.maxTokens = 8192
        self.defaultSystemPrompt = ""
        self.sendWithReturn = false
    }
}
