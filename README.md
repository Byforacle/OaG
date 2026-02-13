# OaG - iOS AI Agent

基于 Claude API 的 iOS AI Agent 应用，支持 Tool Use 工具调用，纯 SwiftUI 构建。

## 功能

### 核心对话
- **流式对话** — 基于 SSE 的实时流式响应，支持中途停止
- **会话管理** — 创建、删除、重命名、置顶、搜索会话
- **模型切换** — 支持 Claude Opus / Sonnet / Haiku，每个会话可独立选择模型
- **图片上传** — 通过相机或相册选取图片，压缩后以 base64 发送给 AI
- **Markdown 渲染** — 支持标题、加粗、斜体、链接、列表、引用块
- **代码块** — 语法高亮显示，一键复制
- **重新生成** — 对最后一条回复重新生成
- **触觉反馈** — 发送、停止、复制等操作提供触觉反馈
- **深色模式** — 跟随系统自动切换

### Agent 能力（新）
- **Tool Use 协议** — 完整支持 Claude API 的 tool_use / tool_result 流程
- **Agent 循环** — 自动执行多轮工具调用，stop_reason 为 tool_use 时自动执行工具并将结果反馈给模型
- **工具注册框架** — ToolExecutor 协议 + ToolRegistry 注册中心，可扩展注册任意工具
- **工具调用可视化** — 聊天界面中展示工具调用参数（可折叠）和执行结果
- **Agent 状态指示** — 实时显示"思考中"/"调用工具: xxx"等状态
- **上下文窗口管理** — Token 估算 + 自动截断，防止超长对话超出上下文限制
- **安全阀** — 最大 25 轮 Agent 迭代，防止无限循环

## 技术栈

| 层级 | 技术 |
|------|------|
| UI | SwiftUI + NavigationSplitView |
| 数据持久化 | SwiftData |
| 网络 | URLSession + AsyncThrowingStream (SSE) |
| 安全存储 | Keychain Services |
| 架构 | MVVM |
| Markdown | MarkdownUI |

## 项目结构

```
OaG/
├── Models/              数据模型
│   ├── APITypes.swift       API 请求/响应/SSE 事件类型
│   ├── MessageContent.swift ContentBlock (text/image/toolUse/toolResult)
│   ├── JSONValue.swift      任意 JSON 值的类型安全表示
│   ├── ToolDefinition.swift 工具定义和 ToolChoice
│   ├── Conversation.swift   会话模型 (SwiftData)
│   ├── Message.swift        消息模型 (SwiftData)
│   ├── AppSettings.swift    应用设置 (SwiftData)
│   └── ClaudeModel.swift    模型枚举
├── Services/            服务层
│   ├── ClaudeAPIClient.swift   API 客户端 (SSE 流式)
│   ├── SSEStreamParser.swift   SSE 事件解析器
│   ├── ToolExecutor.swift      工具执行协议 + ToolRegistry
│   ├── ToolUseAccumulator.swift 流式 tool_use JSON 累加器
│   ├── TokenEstimator.swift    Token 估算
│   ├── Tools/
│   │   └── CalculatorTool.swift 内置计算器工具
│   ├── ImageCompressor.swift   图片压缩
│   ├── KeychainService.swift   Keychain 存取
│   └── HapticManager.swift     触觉反馈
├── ViewModels/          状态管理
│   ├── ChatViewModel.swift          聊天 + Agent 循环
│   ├── ConversationListViewModel.swift 会话列表
│   └── SettingsViewModel.swift      设置
├── Views/
│   ├── Chat/            聊天界面
│   │   ├── ChatView.swift
│   │   ├── MessageBubbleView.swift
│   │   ├── MessageContentView.swift
│   │   ├── InputBarView.swift
│   │   ├── ToolUseBlockView.swift      工具调用可视化
│   │   ├── ToolResultBlockView.swift   工具结果可视化
│   │   └── ImagePreviewView.swift
│   ├── Conversations/   会话列表
│   ├── Settings/        设置页面
│   └── Components/      共享组件
│       ├── AgentStatusView.swift   Agent 状态指示器
│       ├── MarkdownTextView.swift
│       ├── CodeBlockView.swift
│       └── ...
└── Extensions/          工具扩展
```

## 配置

首次启动时会自动弹出设置页面，需要配置：

- **Base URL** — API 代理地址（默认 `https://code.aipor.cc`）
- **API Key** — Claude API 密钥（存储在 Keychain 中）

## 自定义工具

实现 `ToolExecutor` 协议即可注册自定义工具：

```swift
struct MyTool: ToolExecutor {
    var definition: ToolDefinition {
        ToolDefinition(
            name: "my_tool",
            description: "工具描述",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([ /* ... */ ]),
                "required": .array([ /* ... */ ])
            ])
        )
    }

    func execute(input: String) async -> ToolResult {
        // 解析 input JSON，执行逻辑，返回结果
        .success("结果")
    }
}
```

在 `ChatViewModel.registerBuiltinTools()` 中注册：

```swift
toolRegistry.register(MyTool())
```

## 更新日志

### v0.2 — Agent 架构
- 新增 Tool Use 完整协议支持（tool_use / tool_result / content_block_start / input_json_delta）
- 新增 Agent 循环，支持多轮自动工具调用
- 新增 ToolExecutor 协议和 ToolRegistry 工具注册框架
- 新增内置计算器工具
- 新增工具调用/结果可视化组件
- 新增 Agent 状态指示器（思考中/调用工具）
- 新增上下文窗口管理（Token 估算 + 自动截断）
- 新增 JSONValue 类型用于任意 JSON 表示
- 请求体大小限制从 4MB 提升至 10MB

### v0.1 — 基础聊天
- 实现 Claude API 流式对话
- 会话管理（创建、删除、重命名、置顶、搜索）
- 多模型支持（Opus / Sonnet / Haiku）
- 图片上传与压缩
- Markdown 渲染与代码块
- 重新生成回复
- 触觉反馈
- 502 代理错误处理优化

## 要求

- iOS 18.0+
- Xcode 26.2+
- Swift 5.0+
