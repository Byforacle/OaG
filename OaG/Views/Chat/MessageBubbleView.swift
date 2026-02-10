import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let isStreaming: Bool

    private var isUser: Bool { message.role == "user" }

    var body: some View {
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

                if isStreaming {
                    LoadingDotsView()
                        .padding(.leading, 8)
                }
            }

            if !isUser { Spacer(minLength: 40) }
        }
    }
}
