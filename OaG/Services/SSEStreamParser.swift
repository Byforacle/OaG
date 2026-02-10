import Foundation

struct SSEStreamParser: Sendable {
    private var currentEventType: String = ""

    mutating func processLine(_ line: String) -> SSEEvent? {
        if line.hasPrefix("event: ") {
            currentEventType = String(line.dropFirst(7))
            return nil
        }
        if line.hasPrefix("data: ") {
            let jsonString = String(line.dropFirst(6))
            let event = parseData(jsonString, eventType: currentEventType)
            return event
        }
        if line.isEmpty {
            currentEventType = ""
        }
        return nil
    }

    private func parseData(_ json: String, eventType: String) -> SSEEvent? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()

        switch eventType {
        case "message_start":
            guard let parsed = try? decoder.decode(SSEMessageStart.self, from: data) else { return nil }
            return .messageStart(
                messageId: parsed.message.id,
                model: parsed.message.model,
                inputTokens: parsed.message.usage?.inputTokens ?? 0
            )

        case "content_block_delta":
            guard let parsed = try? decoder.decode(SSEContentBlockDelta.self, from: data) else { return nil }
            return .contentBlockDelta(index: parsed.index, text: parsed.delta.text ?? "")

        case "message_delta":
            guard let parsed = try? decoder.decode(SSEMessageDelta.self, from: data) else { return nil }
            return .messageDelta(
                stopReason: parsed.delta.stopReason,
                outputTokens: parsed.usage?.outputTokens ?? 0
            )

        case "message_stop":
            return .messageStop

        case "ping":
            return .ping

        case "error":
            guard let parsed = try? decoder.decode(SSEErrorWrapper.self, from: data) else { return nil }
            return .error(parsed.error)

        default:
            return nil
        }
    }
}
