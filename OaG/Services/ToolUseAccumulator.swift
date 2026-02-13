import Foundation

/// Accumulates streaming tool_use blocks from SSE events.
/// Tool use blocks arrive as: content_block_start (id + name) → multiple input_json_delta → content_block_stop.
struct ToolUseAccumulator: Sendable {
    struct PendingToolUse: Sendable {
        let id: String
        let name: String
        var inputJson: String = ""
    }

    private var pending: [Int: PendingToolUse] = [:]

    mutating func startBlock(index: Int, id: String, name: String) {
        pending[index] = PendingToolUse(id: id, name: name)
    }

    mutating func appendJson(index: Int, fragment: String) {
        pending[index]?.inputJson += fragment
    }

    /// Finishes a block and returns the completed tool use if it was a tool_use block.
    mutating func finishBlock(index: Int) -> PendingToolUse? {
        pending.removeValue(forKey: index)
    }

    func currentToolUse(at index: Int) -> PendingToolUse? {
        pending[index]
    }
}
