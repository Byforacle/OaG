import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var role: String
    var createdAt: Date
    var conversation: Conversation?
    var contentData: Data
    var inputTokens: Int
    var outputTokens: Int

    var contentBlocks: [ContentBlock] {
        get {
            (try? JSONDecoder().decode([ContentBlock].self, from: contentData)) ?? []
        }
        set {
            contentData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var textContent: String {
        contentBlocks.compactMap { block in
            if case .text(let text) = block { return text }
            return nil
        }.joined()
    }

    init(role: String, content: [ContentBlock], conversation: Conversation? = nil) {
        self.id = UUID()
        self.role = role
        self.createdAt = .now
        self.conversation = conversation
        self.contentData = (try? JSONEncoder().encode(content)) ?? Data()
        self.inputTokens = 0
        self.outputTokens = 0
    }
}
