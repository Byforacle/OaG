import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("选择或创建一个会话")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}
