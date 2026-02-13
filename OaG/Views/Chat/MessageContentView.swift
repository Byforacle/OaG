import SwiftUI

struct MessageContentView: View {
    let blocks: [ContentBlock]
    let isUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let text):
                    if isUser {
                        Text(text)
                            .foregroundStyle(Color.userText)
                    } else {
                        MarkdownTextView(text: text)
                    }
                case .image(_, let base64Data):
                    if let data = Data(base64Encoded: base64Data),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                case .toolUse(_, let name, let input):
                    ToolUseBlockView(name: name, input: input)
                case .toolResult(_, let content, let isError):
                    ToolResultBlockView(content: content, isError: isError)
                }
            }
        }
    }
}
