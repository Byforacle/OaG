import SwiftUI
import SwiftData

@Observable
final class SettingsViewModel {
    var baseURL: String = "https://code.aipor.cc"
    var apiKey: String = ""
    var defaultModel: ClaudeModel = .opus
    var maxTokens: Int = 8192
    var defaultSystemPrompt: String = ""

    private var modelContext: ModelContext
    private var settings: AppSettings?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSettings()
    }

    func loadSettings() {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? modelContext.fetch(descriptor).first {
            self.settings = existing
            self.baseURL = existing.baseURL
            self.defaultModel = ClaudeModel.fromLegacyIdentifier(existing.defaultModelIdentifier) ?? .opus
            self.maxTokens = existing.maxTokens
            self.defaultSystemPrompt = existing.defaultSystemPrompt

            // Migrate stale default model identifier
            if existing.defaultModelIdentifier != defaultModel.rawValue {
                existing.defaultModelIdentifier = defaultModel.rawValue
                try? modelContext.save()
            }
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            self.settings = newSettings
        }
        self.apiKey = KeychainService.load(key: "api_key") ?? ""
    }

    func saveSettings() {
        guard let settings else { return }
        settings.baseURL = baseURL
        settings.defaultModelIdentifier = defaultModel.rawValue
        settings.maxTokens = maxTokens
        settings.defaultSystemPrompt = defaultSystemPrompt
        try? modelContext.save()

        if !apiKey.isEmpty {
            KeychainService.save(key: "api_key", value: apiKey)
        }
    }
}
