

import SwiftUI
import PhotosUI
import UIKit

struct ImageSelectionSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    @FocusState private var isTextFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
  
    var body: some View {
        VStack(spacing: 16) {
            // Quick Text Mode Toggle
            Group {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable Text Extraction", isOn: $viewModel.useTextExtraction)
                        .padding()
                        .onAppear {
                            print("🔄 Toggle initialized with: \(viewModel.useTextExtraction)")
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Quick Text Mode")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if viewModel.useTextExtraction {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.yellow)
                                    .imageScale(.small)
                            }
                        }
                        Text("Extracts text for faster processing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .onChange(of: viewModel.useTextExtraction) { newValue in
                    print("📱 Quick Text Mode changed to: \(newValue)")
                }
            }
            .padding(.horizontal)

            Divider()

            // Input Type Selection Buttons
            HStack(spacing: 12) {
                // Camera Button
                ImageOptionCard(
                    icon: "camera.fill",
                    isUsed: viewModel.hasSelectedCamera,
                    isDisabled: !viewModel.canUseImageInput,
                    action: {
                        if viewModel.canUseImageInput {
                            viewModel.isTextInputActive = false
                            isTextFieldFocused = false
                            viewModel.onImageOptionSelected()
                            Task {
                                await viewModel.takePhoto()
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)

                // Gallery Button
                ImageOptionCard(
                    icon: "photo.fill",
                    isUsed: viewModel.hasSelectedGallery,
                    isDisabled: !viewModel.canUseImageInput,
                    action: {
                        if viewModel.canUseImageInput {
                            viewModel.isTextInputActive = false
                            isTextFieldFocused = false
                            viewModel.onImageOptionSelected()
                            Task {
                                await viewModel.selectFromGallery()
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)

                // Text Input Button
                ImageOptionCard(
                    icon: "text.bubble.fill",
                    isUsed: viewModel.isTextInputActive,
                    isDisabled: !viewModel.canUseTextInput,
                    action: {
                        if viewModel.canUseTextInput {
                            viewModel.onImageOptionSelected()
                            viewModel.toggleTextInput()
                            if viewModel.isTextInputActive {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isTextFieldFocused = true
                                }
                            } else {
                                isTextFieldFocused = false
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)

            // Text Input Field
            if viewModel.isTextInputActive {
                VStack(spacing: 12) {
                    TextField("Enter your question here...", text: $viewModel.questionText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                }
                .padding(.horizontal)
            }

            // Selected Images Display
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(zip(viewModel.selectedImages.indices, viewModel.selectedImages)), id: \.0) { index, image in
                            let imageId = viewModel.getImageId(for: image)
                            SelectedImageCell(
                                image: image,
                                isLoading: viewModel.isLoadingTexts[imageId] ?? false,
                                extractionStatus: viewModel.extractionStatus[imageId],
                                extractedText: viewModel.extractedTexts[imageId],
                                showExtractedText: viewModel.useTextExtraction,
                                onDelete: {
                                    viewModel.removeImage(at: index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Generate Button for Selected Content
            if !viewModel.selectedImages.isEmpty || !viewModel.questionText.isEmpty {
                Button {
                    Task {
                        await viewModel.sendAllImages()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "sparkles")
                        Text("Generate Questions")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.isLoading ? Color.gray : Color.green)
                    )
                    .animation(.easeInOut, value: viewModel.isLoading)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
            }
        }
    }
}



// Update ImageOptionCard to support disabled state
struct ImageOptionCard: View {
   let icon: String
   let isUsed: Bool
   let isDisabled: Bool
   let action: () -> Void
   
   var body: some View {
       Button(action: action) {
           VStack(spacing: 12) {
               Image(systemName: icon)
                   .font(.system(size: 30))
           }
           .frame(maxWidth: .infinity)
           .padding(.vertical, 20)
           .foregroundColor(foregroundColor)
           .background(
               RoundedRectangle(cornerRadius: 12)
                   .fill(backgroundColor)
           )
           .overlay(
               RoundedRectangle(cornerRadius: 12)
                   .stroke(strokeColor, lineWidth: 1)
           )
       }
       .disabled(isDisabled)
       .buttonStyle(PlainButtonStyle())
   }
   
   private var foregroundColor: Color {
       if isDisabled {
           return .gray.opacity(0.5)
       }
       return isUsed ? .green : .gray
   }
   
   private var backgroundColor: Color {
       if isDisabled {
           return Color.gray.opacity(0.1)
       }
       return isUsed ? Color.green.opacity(0.1) : Color.gray.opacity(0.1)
   }
   
   private var strokeColor: Color {
       if isDisabled {
           return .clear
       }
       return isUsed ? Color.green.opacity(0.2) : .clear
   }
}

struct SelectedImageCell: View {
    let image: UIImage
    let isLoading: Bool
    let extractionStatus: Bool?
    let extractedText: String?
    let showExtractedText: Bool
    let onDelete: () -> Void
    
    init(
        image: UIImage,
        isLoading: Bool = false,
        extractionStatus: Bool? = nil,
        extractedText: String? = nil,
        showExtractedText: Bool = false,
        onDelete: @escaping () -> Void
    ) {
        self.image = image
        self.isLoading = isLoading
        self.extractionStatus = extractionStatus
        self.extractedText = extractedText
        self.showExtractedText = showExtractedText
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                if showExtractedText {
                    if isLoading {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Extracting text...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else if let status = extractionStatus {
                        HStack(spacing: 4) {
                            Image(systemName: status ? "doc.text.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(status ? .green : .orange)
                                .imageScale(.small)
                            Text(status ? "Text extracted" : "Extraction failed")
                                .font(.caption2)
                                .foregroundColor(status ? .green : .orange)
                        }
                    }
                }
            }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 24, height: 24)
                    )
            }
            .offset(x: 6, y: -6)
        }
    }
}

struct ImageSelectionButtons: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        VStack {
            ImageSelectionButton(
                title: "Select Multiple Photos",
                icon: "photo.on.rectangle"
            ) {
                Task {
                    await viewModel.selectMultiplePhotos()
                }
            }
            
            ImageSelectionButton(
                title: "Take Photo",
                icon: "camera"
            ) {
                Task {
                    await viewModel.takePhoto()
                }
            }
            
            ImageSelectionButton(
                title: "Choose from Gallery",
                icon: "photo"
            ) {
                Task {
                    await viewModel.selectFromGallery()
                }
            }
        }
    }
}

struct ImageSelectionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct SelectedImagesView: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selected Images")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                        ImageCell(
                            image: viewModel.selectedImages[index],
                            onDelete: {
                                viewModel.removeImage(at: index)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            
            GenerateQuestionsButton(viewModel: viewModel)
        }
        .padding(.top, 8)
    }
}

struct ImageCell: View {
    let image: UIImage
    let onDelete: () -> Void
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                .padding(4),
                alignment: .topTrailing
            )
    }
}

struct GenerateQuestionsButton: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        Button {
            Task {
                await viewModel.sendAllImages()
            }
        } label: {
            HStack {
                Spacer()
                Label("Generate Questions", systemImage: "paperplane.fill")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle())
        .padding(.vertical, 8)
    }
}
