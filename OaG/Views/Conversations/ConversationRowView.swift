import SwiftUI

struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if conversation.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Text(conversation.title)
                    .font(.body)
                    .lineLimit(1)
                Spacer()
                Text(conversation.updatedAt.relativeFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(conversation.currentModel?.shortName ?? "")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.fill.tertiary, in: Capsule())
                Text("\(conversation.messages.count) 条消息")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
