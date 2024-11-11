// File: ./AISnapStudy/Views/Components/ImageSelectionSection.swift

import SwiftUI
import PhotosUI
import UIKit


struct ImageSelectionSection: View {
   @ObservedObject var viewModel: QuestionSettingsViewModel
   @FocusState private var isTextFieldFocused: Bool
   @State private var keyboardHeight: CGFloat = 0
   
   var body: some View {
       Section {
           DisclosureGroup(
               isExpanded: .constant(true),
               content: {
                   VStack(spacing: 16) {
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
                       
                       // Text Input Field and Generate Button
                       if viewModel.isTextInputActive {
                           VStack(spacing: 12) {
                               TextField("Enter your question here...", text: $viewModel.questionText)
                                   .textFieldStyle(RoundedBorderTextFieldStyle())
                                   .focused($isTextFieldFocused)
                                   .onChange(of: viewModel.questionText) { newValue in
                                       let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                       viewModel.isUsingTextInput = !trimmed.isEmpty
                                   }
                               
                               // Generate Button for Text Input
                               if !viewModel.questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                   Button {
                                       print("🔵 Generate Questions Button Tapped (Text Input)")
                                       isTextFieldFocused = false
                                       Task {
                                           print("📝 Starting question generation from text")
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
                               }
                           }
                           .padding(.horizontal)
                           .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 20 : 0)
                           .animation(.easeOut, value: keyboardHeight)
                       }
                       
                       // Selected Images Display
                       if !viewModel.selectedImages.isEmpty {
                           VStack(alignment: .leading, spacing: 12) {
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
                                   .padding(.horizontal)
                               }
                               
                               // Generate Button for Images
                               Button {
                                   print("🔵 Generate Questions Button Tapped (Images)")
                                   Task { @MainActor in
                                       print("📝 Starting question generation from images")
                                       print("• Number of images: \(viewModel.selectedImages.count)")
                                       
                                       viewModel.isLoading = true
                                       
                                       do {
                                           await viewModel.sendAllImages()
                                       } catch {
                                           print("❌ Error generating questions: \(error)")
                                       }
                                       
                                       viewModel.isLoading = false
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
                   .padding(.vertical, 8)
               },
               label: {
                   HStack {
                       Text("Question About")
                           .font(.headline)
                       Spacer()
                       if !viewModel.selectedImages.isEmpty {
                           Text("\(viewModel.selectedImages.count) selected")
                               .foregroundColor(viewModel.selectedImages.isEmpty ? .gray : .green)
                       } else if !viewModel.questionText.isEmpty {
                           Text("Text input")
                               .foregroundColor(.green)
                       }
                   }
               }
           )
       }
       .onTapGesture {
           isTextFieldFocused = false
       }
       .onAppear {
           NotificationCenter.default.addObserver(
               forName: UIResponder.keyboardWillShowNotification,
               object: nil,
               queue: .main
           ) { notification in
               if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                   self.keyboardHeight = keyboardFrame.height
               }
           }
           
           NotificationCenter.default.addObserver(
               forName: UIResponder.keyboardWillHideNotification,
               object: nil,
               queue: .main
           ) { _ in
               self.keyboardHeight = 0
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
   let onDelete: () -> Void
   
   var body: some View {
       ZStack(alignment: .topTrailing) {
           Image(uiImage: image)
               .resizable()
               .scaledToFill()
               .frame(width: 100, height: 100)
               .clipShape(RoundedRectangle(cornerRadius: 12))
               .overlay(
                   RoundedRectangle(cornerRadius: 12)
                       .stroke(Color.gray.opacity(0.2), lineWidth: 1)
               )
           
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
