import SwiftUI
import SwiftData

@Observable
final class ChatViewModel {
    var messages: [Message] = []
    var inputText: String = ""
    var attachedImages: [UIImage] = []
    var isStreaming: Bool = false
    var streamingText: String = ""
    var errorMessage: String?
    var showError: Bool = false

    private var conversation: Conversation?
    private var modelContext: ModelContext
    private var apiClient: ClaudeAPIClient?
    private var streamTask: Task<Void, Never>?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadConversation(_ conversation: Conversation) {
        self.conversation = conversation
        self.messages = conversation.sortedMessages
        configureClient()
    }

    func configureClient() {
        let apiKey = KeychainService.load(key: "api_key") ?? ""
        let descriptor = FetchDescriptor<AppSettings>()
        let baseURL = (try? modelContext.fetch(descriptor).first)?.baseURL
            ?? "https://code.aipor.cc"
        guard !apiKey.isEmpty else { return }
        self.apiClient = ClaudeAPIClient(baseURL: baseURL, apiKey: apiKey)
    }

    func send() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !attachedImages.isEmpty else { return }
        guard apiClient != nil else {
            errorMessage = OaGError.noAPIKey.localizedDescription
            showError = true
            return
        }

        // Build user content blocks
        var contentBlocks: [ContentBlock] = []
        for image in attachedImages {
            if let compressed = ImageCompressor.compressForAPI(image) {
                contentBlocks.append(.image(
                    mediaType: compressed.mediaType,
                    base64Data: compressed.base64
                ))
            }
        }
        if !trimmed.isEmpty {
            contentBlocks.append(.text(trimmed))
        }

        // Create and persist user message
        let userMessage = Message(role: "user", content: contentBlocks, conversation: conversation)
        modelContext.insert(userMessage)
        messages.append(userMessage)

        // Clear input
        inputText = ""
        attachedImages = []

        // Create placeholder assistant message
        let assistantMessage = Message(role: "assistant", content: [.text("")], conversation: conversation)
        modelContext.insert(assistantMessage)
        messages.append(assistantMessage)

        // Start streaming
        isStreaming = true
        streamingText = ""
        streamTask = Task { await performStream(assistantMessage: assistantMessage) }
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    private func performStream(assistantMessage: Message) async {
        guard let client = apiClient, let conversation else { return }

        let apiMessages = buildAPIMessages()
        let maxTokens = loadMaxTokens()
        let request = MessagesRequest(
            model: conversation.modelIdentifier,
            maxTokens: maxTokens,
            messages: apiMessages,
            stream: true,
            system: conversation.systemPrompt.isEmpty ? nil : conversation.systemPrompt
        )

        do {
            for try await event in client.streamMessage(request) {
                if Task.isCancelled { break }
                switch event {
                case .contentBlockDelta(_, let text):
                    streamingText += text
                    assistantMessage.contentBlocks = [.text(streamingText)]
                case .messageStart(_, _, let inputTokens):
                    assistantMessage.inputTokens = inputTokens
                case .messageDelta(_, let outputTokens):
                    assistantMessage.outputTokens = outputTokens
                case .error(let apiError):
                    throw OaGError.apiError(apiError.message)
                default:
                    break
                }
            }
            conversation.updatedAt = .now
            if conversation.title == "新对话" && messages.count <= 3 {
                conversation.title = generateTitle(from: streamingText)
            }
            try? modelContext.save()
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        isStreaming = false
    }

    private func buildAPIMessages() -> [APIMessage] {
        // Exclude the last message (empty assistant placeholder)
        messages.dropLast().map { msg in
            APIMessage(
                role: msg.role,
                content: msg.contentBlocks.map { block in
                    switch block {
                    case .text(let t):
                        .text(t)
                    case .image(let mt, let d):
                        .image(mediaType: mt, data: d)
                    }
                }
            )
        }
    }

    private func loadMaxTokens() -> Int {
        let descriptor = FetchDescriptor<AppSettings>()
        return (try? modelContext.fetch(descriptor).first)?.maxTokens ?? 8192
    }

    private func generateTitle(from text: String) -> String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        if firstLine.count > 20 {
            return String(firstLine.prefix(20)) + "..."
        }
        return firstLine.isEmpty ? "新对话" : firstLine
    }
}
