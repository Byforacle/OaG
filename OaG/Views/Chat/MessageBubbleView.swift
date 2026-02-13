import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let isStreaming: Bool
    let isLastAssistantMessage: Bool
    var agentStatus: AgentStatus = .idle
    var onRegenerate: (() -> Void)?

    private var isUser: Bool { message.role == "user" }
    private var isToolResultMessage: Bool {
        message.role == "user" && message.contentBlocks.contains(where: {
            if case .toolResult = $0 { return true }
            return false
        })
    }

    var body: some View {
        if isToolResultMessage {
            VStack(alignment: .leading, spacing: 4) {
                MessageContentView(blocks: message.contentBlocks, isUser: false)
            }
            .padding(.horizontal, 8)
        } else {
            standardBubble
        }
    }

    private var standardBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                MessageContentView(
                    blocks: message.contentBlocks,
                    isUser: isUser
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.userBubble : Color.assistantBubble)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.textContent
                        HapticManager.impact(.light)
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                }

                if isStreaming {
                    if agentStatus != .idle {
                        AgentStatusView(status: agentStatus)
                            .padding(.leading, 8)
                    } else {
                        LoadingDotsView()
                            .padding(.leading, 8)
                    }
                }

                if !isUser && isLastAssistantMessage && !isStreaming && !message.textContent.isEmpty {
                    Button {
                        onRegenerate?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重新生成")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 8)
                    .padding(.top, 2)
                }
            }

            if !isUser { Spacer(minLength: 40) }
        }
    }
}
