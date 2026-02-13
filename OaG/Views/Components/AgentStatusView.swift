import SwiftUI

struct AgentStatusView: View {
    let status: AgentStatus

    var body: some View {
        switch status {
        case .idle:
            EmptyView()
        case .thinking:
            statusRow(icon: "brain", text: "思考中...", color: .purple)
        case .callingTool(let name):
            statusRow(icon: "wrench.and.screwdriver", text: "调用工具: \(name)", color: .orange)
        case .processing:
            statusRow(icon: "gearshape.2", text: "处理中...", color: .blue)
        }
    }

    private func statusRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .symbolEffect(.pulse, isActive: true)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.08), in: Capsule())
    }
}
