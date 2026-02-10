import SwiftUI

struct MarkdownTextView: View {
    let text: String

    var body: some View {
        let segments = parseSegments(text)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let content):
                    if let attributed = try? AttributedString(
                        markdown: content,
                        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                    ) {
                        Text(attributed)
                            .foregroundStyle(Color.assistantText)
                            .textSelection(.enabled)
                    } else {
                        Text(content)
                            .foregroundStyle(Color.assistantText)
                            .textSelection(.enabled)
                    }
                case .code(let language, let code):
                    CodeBlockView(language: language, code: code)
                }
            }
        }
    }

    private enum Segment {
        case text(String)
        case code(language: String, code: String)
    }

    private func parseSegments(_ text: String) -> [Segment] {
        var segments: [Segment] = []
        let pattern = "```(\\w*)\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [.text(text)]
        }

        let nsText = text as NSString
        var lastEnd = 0
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            let matchRange = match.range
            if matchRange.location > lastEnd {
                let before = nsText.substring(with: NSRange(location: lastEnd, length: matchRange.location - lastEnd))
                let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    segments.append(.text(trimmed))
                }
            }
            let language = nsText.substring(with: match.range(at: 1))
            let code = nsText.substring(with: match.range(at: 2))
                .trimmingCharacters(in: .newlines)
            segments.append(.code(language: language, code: code))
            lastEnd = matchRange.location + matchRange.length
        }

        if lastEnd < nsText.length {
            let remaining = nsText.substring(from: lastEnd)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !remaining.isEmpty {
                segments.append(.text(remaining))
            }
        }

        if segments.isEmpty {
            segments.append(.text(text))
        }

        return segments
    }
}
