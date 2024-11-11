// File: ./AISnapStudy/Views/Components/ImageSelectionSection.swift

import SwiftUI
import PhotosUI

struct ImageSelectionSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        Section(header: Text("Select Images"), footer: footerView) {
            // Image Selection Buttons
            ImageSelectionButtons(viewModel: viewModel)
            
            // Selected Images Display
            if !viewModel.selectedImages.isEmpty {
                SelectedImagesView(viewModel: viewModel)
            }
        }
    }
    
    private var footerView: some View {
        Text(viewModel.selectedImages.isEmpty ? "No images selected" : "\(viewModel.selectedImages.count) images selected")
            .font(.caption)
            .foregroundColor(.secondary)
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
