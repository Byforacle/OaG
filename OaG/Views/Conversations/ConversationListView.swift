import SwiftUI

struct ConversationListView: View {
    @Bindable var viewModel: ConversationListViewModel
    @Binding var selectedConversation: Conversation?
    @Binding var showSettings: Bool
    @State private var renamingConversation: Conversation?
    @State private var renameText = ""

    var body: some View {
        List(selection: $selectedConversation) {
            if !viewModel.pinnedConversations.isEmpty {
                Section("置顶") {
                    ForEach(viewModel.pinnedConversations, id: \.id) { conversation in
                        NavigationLink(value: conversation) {
                            ConversationRowView(conversation: conversation)
                        }
                        .swipeActions(edge: .trailing) {
                            deleteButton(for: conversation)
                        }
                        .swipeActions(edge: .leading) {
                            pinButton(for: conversation)
                            renameButton(for: conversation)
                        }
                    }
                }
            }

            Section(viewModel.pinnedConversations.isEmpty ? "会话" : "全部") {
                ForEach(viewModel.unpinnedConversations, id: \.id) { conversation in
                    NavigationLink(value: conversation) {
                        ConversationRowView(conversation: conversation)
                    }
                    .swipeActions(edge: .trailing) {
                        deleteButton(for: conversation)
                    }
                    .swipeActions(edge: .leading) {
                        pinButton(for: conversation)
                        renameButton(for: conversation)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜索会话")
        .navigationTitle("OaG")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let conv = viewModel.createConversation()
                    selectedConversation = conv
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("重命名会话", isPresented: .init(
            get: { renamingConversation != nil },
            set: { if !$0 { renamingConversation = nil } }
        )) {
            TextField("会话名称", text: $renameText)
            Button("取消", role: .cancel) { renamingConversation = nil }
            Button("确定") {
                if let conv = renamingConversation, !renameText.isEmpty {
                    viewModel.renameConversation(conv, to: renameText)
                }
                renamingConversation = nil
            }
        }
    }

    private func deleteButton(for conversation: Conversation) -> some View {
        Button(role: .destructive) {
            if selectedConversation?.id == conversation.id {
                selectedConversation = nil
            }
            viewModel.deleteConversation(conversation)
        } label: {
            Label("删除", systemImage: "trash")
        }
    }

    private func pinButton(for conversation: Conversation) -> some View {
        Button {
            viewModel.togglePin(conversation)
        } label: {
            Label(
                conversation.isPinned ? "取消置顶" : "置顶",
                systemImage: conversation.isPinned ? "pin.slash" : "pin"
            )
        }
        .tint(.orange)
    }

    private func renameButton(for conversation: Conversation) -> some View {
        Button {
            renameText = conversation.title
            renamingConversation = conversation
        } label: {
            Label("重命名", systemImage: "pencil")
        }
        .tint(.blue)
    }
}
