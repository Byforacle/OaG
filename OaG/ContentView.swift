import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedConversation: Conversation?
    @State private var showSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var conversationListVM: ConversationListViewModel?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            if let vm = conversationListVM {
                ConversationListView(
                    viewModel: vm,
                    selectedConversation: $selectedConversation,
                    showSettings: $showSettings
                )
            }
        } detail: {
            if let conversation = selectedConversation {
                ChatView(conversation: conversation)
            } else {
                EmptyStateView()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            if conversationListVM == nil {
                let vm = ConversationListViewModel(modelContext: modelContext)
                vm.fetchConversations()
                conversationListVM = vm
                checkFirstLaunch()
            }
        }
    }

    private func checkFirstLaunch() {
        if KeychainService.load(key: "api_key") == nil {
            showSettings = true
        }
    }
}
