import Foundation

/// Result of executing a tool.
struct ToolResult: Sendable {
    let content: String
    let isError: Bool

    static func success(_ content: String) -> ToolResult {
        ToolResult(content: content, isError: false)
    }

    static func failure(_ message: String) -> ToolResult {
        ToolResult(content: message, isError: true)
    }
}

/// Protocol for tool implementations.
protocol ToolExecutor: Sendable {
    var definition: ToolDefinition { get }
    func execute(input: String) async -> ToolResult
}

/// Central registry for all available tools (built-in + MCP).
final class ToolRegistry: @unchecked Sendable {
    private var tools: [String: ToolExecutor] = [:]
    private let lock = NSLock()

    func register(_ tool: ToolExecutor) {
        lock.lock()
        defer { lock.unlock() }
        tools[tool.definition.name] = tool
    }

    func unregister(name: String) {
        lock.lock()
        defer { lock.unlock() }
        tools.removeValue(forKey: name)
    }

    func execute(name: String, input: String) async -> ToolResult {
        lock.lock()
        let tool = tools[name]
        lock.unlock()

        guard let tool else {
            return .failure("Unknown tool: \(name)")
        }
        return await tool.execute(input: input)
    }

    func allDefinitions() -> [ToolDefinition] {
        lock.lock()
        defer { lock.unlock() }
        return tools.values.map(\.definition)
    }

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return tools.isEmpty
    }
}
