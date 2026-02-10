import SwiftUI
import SwiftData

@main
struct OaGApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Conversation.self, Message.self, AppSettings.self])
    }
}
