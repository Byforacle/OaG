import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel?

    var body: some View {
        NavigationStack {
            if let vm = viewModel {
                settingsForm(vm: vm)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SettingsViewModel(modelContext: modelContext)
            }
        }
    }

    private func settingsForm(vm: SettingsViewModel) -> some View {
        Form {
            Section("API 配置") {
                HStack {
                    Text("Base URL")
                    Spacer()
                    TextField("https://api.anthropic.com", text: Binding(
                        get: { vm.baseURL },
                        set: { vm.baseURL = $0 }
                    ))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                }
                HStack {
                    Text("API Key")
                    Spacer()
                    SecureField("sk-...", text: Binding(
                        get: { vm.apiKey },
                        set: { vm.apiKey = $0 }
                    ))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                }
            }

            Section("默认设置") {
                Picker("默认模型", selection: Binding(
                    get: { vm.defaultModel },
                    set: { vm.defaultModel = $0 }
                )) {
                    ForEach(ClaudeModel.allCases) { model in
                        Text(model.displayName).tag(model)
                    }
                }

                HStack {
                    Text("最大 Tokens")
                    Spacer()
                    TextField("8192", value: Binding(
                        get: { vm.maxTokens },
                        set: { vm.maxTokens = $0 }
                    ), format: .number)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .foregroundStyle(.secondary)
                }
            }

            Section("System Prompt") {
                TextEditor(text: Binding(
                    get: { vm.defaultSystemPrompt },
                    set: { vm.defaultSystemPrompt = $0 }
                ))
                .frame(minHeight: 80)
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    vm.saveSettings()
                    dismiss()
                }
                .bold()
            }
        }
    }
}
