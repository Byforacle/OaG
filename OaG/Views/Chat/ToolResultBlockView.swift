import SwiftUI

struct ToolResultBlockView: View {
    let content: String
    let isError: Bool
    @State private var isExpanded = false

    private var accentColor: Color { isError ? .red : .green }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isError ? "xmark.circle" : "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(accentColor)
                    Text(isError ? "工具错误" : "工具结果")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .lineLimit(20)
            }
        }
        .padding(10)
        .background(accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}
