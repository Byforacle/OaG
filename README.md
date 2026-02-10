# OaG - iOS AI 智能助手

基于 Claude API 的个人 iOS AI 助手应用，纯 SwiftUI 构建，零第三方依赖。

## 功能

- **流式对话** — 基于 SSE 的实时流式响应，支持中途停止
- **会话管理** — 创建、删除、重命名、置顶、搜索会话
- **模型切换** — 支持 Claude Opus / Sonnet / Haiku，每个会话可独立选择模型
- **图片上传** — 通过相机或相册选取图片，压缩后以 base64 发送给 AI
- **Markdown 渲染** — 支持加粗、斜体、链接、列表等基础 Markdown 语法
- **代码块** — 独立渲染代码块，等宽字体显示，一键复制
- **深色模式** — 跟随系统自动切换

## 技术栈

| 层级 | 技术 |
|------|------|
| UI | SwiftUI + NavigationSplitView |
| 数据持久化 | SwiftData |
| 网络 | URLSession + AsyncThrowingStream (SSE) |
| 安全存储 | Keychain Services |
| 架构 | MVVM |

## 项目结构

```
OaG/
├── Models/          数据模型 (SwiftData + API 类型)
├── Services/        网络层、SSE 解析、图片压缩、Keychain
├── ViewModels/      状态管理 (Chat / ConversationList / Settings)
├── Views/
│   ├── Chat/        聊天界面
│   ├── Conversations/ 会话列表
│   ├── Settings/    设置页面
│   └── Components/  共享组件 (Markdown、代码块、图片选择器等)
└── Extensions/      工具扩展
```

## 配置

首次启动时会自动弹出设置页面，需要配置：

- **Base URL** — API 代理地址（默认 `https://code.aipor.cc`）
- **API Key** — Claude API 密钥（`sk-` 格式，存储在 Keychain 中）

## 要求

- iOS 18.0+
- Xcode 26.2+
- Swift 5.0+
