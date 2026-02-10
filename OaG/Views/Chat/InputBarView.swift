import SwiftUI

struct InputBarView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var showImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceActionSheet = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.attachedImages.isEmpty {
                ImagePreviewView(images: $viewModel.attachedImages)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }

            HStack(alignment: .bottom, spacing: 8) {
                Button {
                    showSourceActionSheet = true
                } label: {
                    Image(systemName: "photo.badge.plus")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .confirmationDialog("选择图片来源", isPresented: $showSourceActionSheet) {
                    Button("相机") {
                        imageSourceType = .camera
                        showImagePicker = true
                    }
                    Button("相册") {
                        imageSourceType = .photoLibrary
                        showImagePicker = true
                    }
                    Button("取消", role: .cancel) {}
                }

                TextField("输入消息...", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 20))
                    .focused($isTextFieldFocused)

                if viewModel.isStreaming {
                    Button {
                        viewModel.stopStreaming()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                } else {
                    Button {
                        viewModel.send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .disabled(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        && viewModel.attachedImages.isEmpty
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(sourceType: imageSourceType) { image in
                viewModel.attachedImages.append(image)
            }
        }
    }
}
