import SwiftUI
import MarkdownUI

struct MarkdownTextView: View {
    let text: String

    var body: some View {
        Markdown(text)
            .markdownTheme(chatTheme)
            .textSelection(.enabled)
    }

    private var chatTheme: Theme {
        Theme()
            .text {
                ForegroundColor(Color.assistantText)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                BackgroundColor(Color.codeBackground)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.5))
                        ForegroundColor(Color.assistantText)
                    }
                    .padding(.bottom, 4)
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.3))
                        ForegroundColor(Color.assistantText)
                    }
                    .padding(.bottom, 2)
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(1.1))
                        ForegroundColor(Color.assistantText)
                    }
            }
            .blockquote { configuration in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 3)
                    configuration.label
                        .markdownTextStyle {
                            ForegroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                }
                .padding(.vertical, 2)
            }
            .codeBlock { configuration in
                CodeBlockView(
                    language: configuration.language ?? "",
                    code: configuration.content
                )
            }
    }
}
