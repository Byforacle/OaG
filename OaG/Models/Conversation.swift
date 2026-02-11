import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var systemPrompt: String
    var modelIdentifier: String

    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message]

    init(
        title: String = "新对话",
        systemPrompt: String = "",
        modelIdentifier: String = ClaudeModel.opus.rawValue
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
        self.isPinned = false
        self.systemPrompt = systemPrompt
        self.modelIdentifier = modelIdentifier
        self.messages = []
    }

    var sortedMessages: [Message] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }

    var currentModel: ClaudeModel? {
        ClaudeModel.fromLegacyIdentifier(modelIdentifier)
    }
}
