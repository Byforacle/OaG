import Foundation

struct CalculatorTool: ToolExecutor {
    var definition: ToolDefinition {
        ToolDefinition(
            name: "calculator",
            description: "Perform basic arithmetic (add, subtract, multiply, divide)",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "operation": .object([
                        "type": .string("string"),
                        "description": .string("The operation to perform: add, subtract, multiply, divide"),
                        "enum": .array([.string("add"), .string("subtract"), .string("multiply"), .string("divide")])
                    ]),
                    "a": .object([
                        "type": .string("number"),
                        "description": .string("First number")
                    ]),
                    "b": .object([
                        "type": .string("number"),
                        "description": .string("Second number")
                    ])
                ]),
                "required": .array([.string("operation"), .string("a"), .string("b")])
            ])
        )
    }

    func execute(input: String) async -> ToolResult {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let operation = json["operation"] as? String,
              let a = json["a"] as? Double,
              let b = json["b"] as? Double else {
            return .failure("无法解析输入参数")
        }

        let result: Double
        switch operation {
        case "add":      result = a + b
        case "subtract": result = a - b
        case "multiply": result = a * b
        case "divide":
            guard b != 0 else { return .failure("除数不能为零") }
            result = a / b
        default:
            return .failure("不支持的运算: \(operation)")
        }

        // Format: drop .0 for integers
        let formatted = result.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", result)
            : String(result)
        return .success("\(a) \(operation) \(b) = \(formatted)")
    }
}
