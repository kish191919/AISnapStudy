import SwiftUI

import SwiftUI

struct QuestionAboutSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    @Binding var isTextInputSelected: Bool

    var body: some View {
        VStack(spacing: 16) { // DisclosureGroup 제거
            // 기존 이미지 옵션 카드
            HStack(spacing: 12) {
                ImageOptionCard(
                    icon: "camera.fill",
                    isUsed: viewModel.hasSelectedCamera,
                    isDisabled: !viewModel.canUseImageInput,
                    action: {
                        if viewModel.canUseImageInput {
                            isTextInputSelected = false
                            Task { await viewModel.takePhoto() }
                        }
                    }
                )

                ImageOptionCard(
                    icon: "photo.fill",
                    isUsed: viewModel.hasSelectedGallery,
                    isDisabled: !viewModel.canUseImageInput,
                    action: {
                        if viewModel.canUseImageInput {
                            isTextInputSelected = false
                            Task { await viewModel.selectFromGallery() }
                        }
                    }
                )

                ImageOptionCard(
                    icon: "text.bubble.fill",
                    isUsed: viewModel.isTextInputActive,
                    isDisabled: !viewModel.canUseTextInput,
                    action: {
                        isTextInputSelected.toggle()
                        viewModel.toggleTextInput()
                    }
                )
            }
            .padding(.horizontal)

            // 🟢 useTextExtraction 토글 추가
            Toggle("Enable Text Extraction", isOn: $viewModel.useTextExtraction)
                .padding(.horizontal)
                .onChange(of: viewModel.useTextExtraction) { newValue in
                    print("📱 useTextExtraction changed to: \(newValue)")
                }

            // 텍스트 입력 필드
            if viewModel.isTextInputActive {
                TextField("Enter your question here...", text: $viewModel.questionText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 선택한 이미지 표시
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                            SelectedImageCell(
                                image: viewModel.selectedImages[index],
                                onDelete: {
                                    viewModel.removeImage(at: index)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listRowSpacing(0)
    }
}
