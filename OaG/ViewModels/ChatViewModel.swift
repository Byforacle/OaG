import SwiftUI
import SwiftData

enum AgentStatus: Equatable {
    case idle
    case thinking
    case callingTool(name: String)
    case processing
}

@Observable
final class ChatViewModel {
    var messages: [Message] = []
    var inputText: String = ""
    var attachedImages: [UIImage] = []
    var isStreaming: Bool = false
    var streamingText: String = ""
    var errorMessage: String?
    var showError: Bool = false
    var agentStatus: AgentStatus = .idle

    private var conversation: Conversation?
    private var modelContext: ModelContext
    private var apiClient: ClaudeAPIClient?
    private var streamTask: Task<Void, Never>?

    let toolRegistry = ToolRegistry()
    private let maxAgentIterations = 25
    private let maxRetries = 3

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadConversation(_ conversation: Conversation) {
        self.conversation = conversation
        self.messages = conversation.sortedMessages

        if let resolved = ClaudeModel.fromLegacyIdentifier(conversation.modelIdentifier),
           conversation.modelIdentifier != resolved.rawValue {
            conversation.modelIdentifier = resolved.rawValue
            try? modelContext.save()
        }

        configureClient()
        registerBuiltinTools()
    }

    private func registerBuiltinTools() {
        toolRegistry.register(CalculatorTool())
    }

    func configureClient() {
        let apiKey = KeychainService.load(key: "api_key") ?? ""
        let descriptor = FetchDescriptor<AppSettings>()
        let baseURL = (try? modelContext.fetch(descriptor).first)?.baseURL
            ?? "https://code.aipor.cc"
        guard !apiKey.isEmpty else { return }
        self.apiClient = ClaudeAPIClient(baseURL: baseURL, apiKey: apiKey)
    }

    // MARK: - Public Actions

    func send() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !attachedImages.isEmpty else { return }
        guard apiClient != nil else {
            errorMessage = OaGError.noAPIKey.localizedDescription
            showError = true
            return
        }

        HapticManager.impact(.medium)

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

        let userMessage = Message(role: "user", content: contentBlocks, conversation: conversation)
        modelContext.insert(userMessage)
        messages.append(userMessage)

        inputText = ""
        attachedImages = []

        let assistantMessage = Message(role: "assistant", content: [.text("")], conversation: conversation)
        modelContext.insert(assistantMessage)
        messages.append(assistantMessage)

        isStreaming = true
        streamingText = ""
        agentStatus = .thinking
        streamTask = Task { await performAgentLoop(assistantMessage: assistantMessage) }
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        agentStatus = .idle
        HapticManager.impact(.light)
    }

    func regenerate() {
        guard messages.count >= 2,
              let lastAssistant = messages.last,
              lastAssistant.role == "assistant",
              !isStreaming
        else { return }

        guard apiClient != nil else {
            errorMessage = OaGError.noAPIKey.localizedDescription
            showError = true
            return
        }

        HapticManager.impact(.medium)

        modelContext.delete(lastAssistant)
        messages.removeLast()

        let newAssistant = Message(role: "assistant", content: [.text("")], conversation: conversation)
        modelContext.insert(newAssistant)
        messages.append(newAssistant)

        isStreaming = true
        streamingText = ""
        agentStatus = .thinking
        streamTask = Task { await performAgentLoop(assistantMessage: newAssistant) }
    }

    // MARK: - Agent Loop

    private func performAgentLoop(assistantMessage: Message) async {
        guard let client = apiClient, let conversation else { return }

        var currentAssistant = assistantMessage
        var iteration = 0

        while iteration < maxAgentIterations {
            iteration += 1
            agentStatus = .thinking

            let (stopReason, contentBlocks) = await performSingleStream(
                client: client,
                conversation: conversation,
                assistantMessage: currentAssistant
            )

            guard !Task.isCancelled else { break }

            if stopReason == "tool_use" && !toolRegistry.isEmpty {
                // Extract tool_use blocks
                let toolUseBlocks = contentBlocks.compactMap { block -> (id: String, name: String, input: String)? in
                    if case .toolUse(let id, let name, let input) = block {
                        return (id, name, input)
                    }
                    return nil
                }

                guard !toolUseBlocks.isEmpty else { break }

                // Execute each tool and collect results
                var resultBlocks: [ContentBlock] = []
                for toolUse in toolUseBlocks {
                    agentStatus = .callingTool(name: toolUse.name)
                    let result = await toolRegistry.execute(name: toolUse.name, input: toolUse.input)
                    resultBlocks.append(.toolResult(
                        toolUseId: toolUse.id,
                        content: result.content,
                        isError: result.isError
                    ))
                }

                // Create tool_result message (role: "user" per API contract)
                let resultMessage = Message(role: "user", content: resultBlocks, conversation: conversation)
                modelContext.insert(resultMessage)
                messages.append(resultMessage)

                // Create new assistant placeholder for next turn
                let nextAssistant = Message(role: "assistant", content: [.text("")], conversation: conversation)
                modelContext.insert(nextAssistant)
                messages.append(nextAssistant)

                streamingText = ""
                currentAssistant = nextAssistant
                // Continue loop
            } else {
                // end_turn, max_tokens, or no tools — done
                break
            }
        }

        if iteration >= maxAgentIterations {
            errorMessage = OaGError.maxIterationsReached.localizedDescription
            showError = true
        }

        conversation.updatedAt = .now
        if conversation.title == "新对话" && messages.count <= 3 {
            conversation.title = generateTitle(from: currentAssistant.textContent)
        }
        try? modelContext.save()
        isStreaming = false
        agentStatus = .idle
    }

    // MARK: - Single Stream Turn

    /// Performs a single API stream request and returns (stopReason, contentBlocks).
    private func performSingleStream(
        client: ClaudeAPIClient,
        conversation: Conversation,
        assistantMessage: Message
    ) async -> (String?, [ContentBlock]) {
        let apiMessages = buildAPIMessages()
        let maxTokens = loadMaxTokens()
        let tools = toolRegistry.isEmpty ? nil : toolRegistry.allDefinitions()

        let request = MessagesRequest(
            model: conversation.modelIdentifier,
            maxTokens: maxTokens,
            messages: apiMessages,
            stream: true,
            system: conversation.systemPrompt.isEmpty ? nil : conversation.systemPrompt,
            tools: tools,
            toolChoice: nil
        )

        var accumulator = ToolUseAccumulator()
        var contentBlocks: [ContentBlock] = []
        var stopReason: String?
        var currentText = ""

        do {
            for try await event in client.streamMessage(request) {
                if Task.isCancelled { break }
                switch event {
                case .messageStart(_, _, let inputTokens):
                    assistantMessage.inputTokens = inputTokens

                case .contentBlockStart(let index, let type, let id, let name):
                    if type == "tool_use", let id, let name {
                        accumulator.startBlock(index: index, id: id, name: name)
                        agentStatus = .callingTool(name: name)
                    }

                case .contentBlockDelta(_, let text):
                    currentText += text
                    streamingText = currentText
                    // Update assistant message with current text for live display
                    var blocks = contentBlocks
                    blocks.append(.text(currentText))
                    assistantMessage.contentBlocks = blocks

                case .inputJsonDelta(let index, let partialJson):
                    accumulator.appendJson(index: index, fragment: partialJson)

                case .contentBlockStop(let index):
                    if let toolUse = accumulator.finishBlock(index: index) {
                        contentBlocks.append(.toolUse(
                            id: toolUse.id,
                            name: toolUse.name,
                            input: toolUse.inputJson
                        ))
                        // Update display
                        assistantMessage.contentBlocks = contentBlocks + (currentText.isEmpty ? [] : [.text(currentText)])
                    } else if !currentText.isEmpty {
                        // Text block finished
                        contentBlocks.append(.text(currentText))
                        currentText = ""
                    }

                case .messageDelta(let reason, let outputTokens):
                    stopReason = reason
                    assistantMessage.outputTokens = outputTokens

                case .error(let apiError):
                    throw OaGError.apiError(apiError.message)

                case .messageStop, .ping:
                    break
                }
            }

            // Finalize: if there's remaining text, add it
            if !currentText.isEmpty && !contentBlocks.contains(where: {
                if case .text(let t) = $0 { return t == currentText }
                return false
            }) {
                contentBlocks.append(.text(currentText))
            }

            assistantMessage.contentBlocks = contentBlocks
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        return (stopReason, contentBlocks)
    }

    // MARK: - Helpers

    private func buildAPIMessages() -> [APIMessage] {
        // Exclude the last message (empty assistant placeholder)
        let relevantMessages = Array(messages.dropLast())
        guard !relevantMessages.isEmpty else { return [] }

        let lastIndex = relevantMessages.count - 1

        var apiMessages = relevantMessages.enumerated().map { index, msg -> APIMessage in
            let isLatestUserMessage = (index == lastIndex && msg.role == "user")

            let apiBlocks: [APIContentBlock] = msg.contentBlocks.compactMap { block in
                switch block {
                case .text(let t):
                    return .text(t)
                case .image(let mt, let d):
                    if isLatestUserMessage {
                        return .image(mediaType: mt, data: d)
                    } else {
                        return .text("[image]")
                    }
                case .toolUse(let id, let name, let input):
                    return .toolUse(id: id, name: name, input: input)
                case .toolResult(let toolUseId, let content, let isError):
                    return .toolResult(
                        toolUseId: toolUseId,
                        content: [.text(content)],
                        isError: isError
                    )
                }
            }

            return APIMessage(role: msg.role, content: apiBlocks)
        }

        // Context window management: estimate tokens and truncate if needed
        let budget = TokenEstimator.contextWindow(for: conversation?.modelIdentifier ?? "")
        let maxInputBudget = Int(Double(budget) * 0.8) // Reserve 20% for output
        var totalTokens = TokenEstimator.estimateMessages(apiMessages)

        while totalTokens > maxInputBudget && apiMessages.count > 2 {
            // Remove the second message (keep first for context continuity)
            apiMessages.remove(at: 1)
            totalTokens = TokenEstimator.estimateMessages(apiMessages)
        }

        return apiMessages
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
