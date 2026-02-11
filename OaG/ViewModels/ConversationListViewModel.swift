import SwiftUI
import SwiftData

@Observable
final class ConversationListViewModel {
    var conversations: [Conversation] = []
    var searchText: String = ""

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var pinnedConversations: [Conversation] {
        filtered.filter(\.isPinned)
    }

    var unpinnedConversations: [Conversation] {
        filtered.filter { !$0.isPinned }
    }

    private var filtered: [Conversation] {
        let sorted = conversations.sorted { $0.updatedAt > $1.updatedAt }
        if searchText.isEmpty { return sorted }
        return sorted.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    func fetchConversations() {
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        conversations = (try? modelContext.fetch(descriptor)) ?? []
    }

    @discardableResult
    func createConversation() -> Conversation {
        let settings = loadSettings()
        let model = ClaudeModel.fromLegacyIdentifier(settings?.defaultModelIdentifier ?? "") ?? .opus
        let conversation = Conversation(
            systemPrompt: settings?.defaultSystemPrompt ?? "",
            modelIdentifier: model.rawValue
        )
        modelContext.insert(conversation)
        try? modelContext.save()
        fetchConversations()
        return conversation
    }

    func deleteConversation(_ conversation: Conversation) {
        modelContext.delete(conversation)
        try? modelContext.save()
        fetchConversations()
    }

    func renameConversation(_ conversation: Conversation, to newTitle: String) {
        conversation.title = newTitle
        try? modelContext.save()
    }

    func togglePin(_ conversation: Conversation) {
        conversation.isPinned.toggle()
        try? modelContext.save()
        fetchConversations()
    }

    private func loadSettings() -> AppSettings? {
        let descriptor = FetchDescriptor<AppSettings>()
        return try? modelContext.fetch(descriptor).first
    }
}
