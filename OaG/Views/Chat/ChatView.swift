import SwiftUI
import SwiftData

struct ChatView: View {
    let conversation: Conversation
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ChatViewModel?

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            Divider()
            if let vm = viewModel {
                InputBarView(viewModel: vm)
            }
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                modelPickerMenu
            }
        }
        .alert("错误", isPresented: Binding(
            get: { viewModel?.showError ?? false },
            set: { viewModel?.showError = $0 }
        )) {
            Button("确定") { viewModel?.showError = false }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
        .onAppear { setupViewModel() }
        .onChange(of: conversation.id) { setupViewModel() }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel?.messages ?? [], id: \.id) { message in
                        MessageBubbleView(
                            message: message,
                            isStreaming: isStreamingMessage(message),
                            isLastAssistantMessage: isLastAssistant(message),
                            agentStatus: isStreamingMessage(message) ? (viewModel?.agentStatus ?? .idle) : .idle,
                            onRegenerate: { viewModel?.regenerate() }
                        )
                        .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel?.streamingText) {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel?.messages.count) {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel?.agentStatus) {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private var modelPickerMenu: some View {
        Menu {
            ForEach(ClaudeModel.allCases) { model in
                Button {
                    conversation.modelIdentifier = model.rawValue
                } label: {
                    HStack {
                        Text(model.displayName)
                        if conversation.modelIdentifier == model.rawValue {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text(conversation.currentModel?.shortName ?? "Model")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.fill.tertiary, in: Capsule())
        }
    }

    private func setupViewModel() {
        let vm = ChatViewModel(modelContext: modelContext)
        vm.loadConversation(conversation)
        viewModel = vm
    }

    private func isStreamingMessage(_ message: Message) -> Bool {
        guard viewModel?.isStreaming == true else { return false }
        return message.id == viewModel?.messages.last?.id
    }

    private func isLastAssistant(_ message: Message) -> Bool {
        guard let vm = viewModel else { return false }
        return message.id == vm.messages.last?.id && message.role == "assistant"
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastId = viewModel?.messages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }
}
