import Foundation

enum TokenEstimator {
    /// Rough token estimate: ~4 chars/token for Latin, ~2 chars/token for CJK.
    static func estimate(_ text: String) -> Int {
        var cjk = 0
        var other = 0
        for scalar in text.unicodeScalars {
            if scalar.value > 0x2E80 {
                cjk += 1
            } else {
                other += 1
            }
        }
        return max((cjk + 1) / 2 + (other + 3) / 4, 1)
    }

    static func estimateBlocks(_ blocks: [APIContentBlock]) -> Int {
        blocks.reduce(0) { total, block in
            switch block {
            case .text(let t):
                return total + estimate(t)
            case .image:
                // Images cost ~1600 tokens on average
                return total + 1600
            case .toolUse(_, let name, let input):
                return total + estimate(name) + estimate(input)
            case .toolResult(_, let content, _):
                return total + content.reduce(0) { sum, c in
                    switch c {
                    case .text(let t): return sum + estimate(t)
                    case .image: return sum + 1600
                    }
                }
            }
        }
    }

    static func estimateMessages(_ messages: [APIMessage]) -> Int {
        messages.reduce(0) { total, msg in
            // ~4 tokens overhead per message (role, formatting)
            total + 4 + estimateBlocks(msg.content)
        }
    }

    /// Context window sizes per model (input tokens).
    static func contextWindow(for modelIdentifier: String) -> Int {
        // All current Claude models have 200k context
        200_000
    }
}
