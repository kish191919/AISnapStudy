

import SwiftUI
import PhotosUI

struct QuestionSettingsView: View {
    let subject: Subject
    @StateObject private var viewModel: QuestionSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(subject: Subject, homeViewModel: HomeViewModel) {
        self.subject = subject
        self._viewModel = StateObject(wrappedValue: QuestionSettingsViewModel(subject: subject, homeViewModel: homeViewModel))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Difficulty Selection
                Section("Difficulty Level") {
                    Picker("Difficulty", selection: $viewModel.difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue.capitalized)
                                .tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Question Types
                Section("Question Types") {
                    VStack(spacing: 10) {
                        QuestionTypeCounter(
                            title: "Multiple Choice",
                            count: $viewModel.multipleChoiceCount
                        )
                        
                        QuestionTypeCounter(
                            title: "Fill in the Blanks",
                            count: $viewModel.fillInBlanksCount
                        )
                        
                        QuestionTypeCounter(
                            title: "Matching",
                            count: $viewModel.matchingCount
                        )
                    }
                }
                
                // Image Selection
                if viewModel.hasValidQuestionCount {
                    Section(header: Text("Select Images"), footer: imagesSectionFooter) {
                        // Multiple Photo Selection Button
                        Button {
                            Task {
                                await viewModel.selectMultiplePhotos()
                            }
                        } label: {
                            HStack {
                                Label("Select Multiple Photos", systemImage: "photo.on.rectangle")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Camera Button
                        Button {
                            Task {
                                await viewModel.takePhoto()
                            }
                        } label: {
                            HStack {
                                Label("Take Photo", systemImage: "camera")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Gallery Button
                        Button {
                            Task {
                                await viewModel.selectFromGallery()
                            }
                        } label: {
                            HStack {
                                Label("Choose from Gallery", systemImage: "photo")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Selected Images Display
                        if !viewModel.selectedImages.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Selected Images")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                                            imageCell(for: index)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                
                                generateQuestionsButton
                            }
                            .padding(.top, 8)
                        }
                    }
                } else {
                    Section {
                        Text("Please select at least one question type")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    viewModel.resetCounts()
                    dismiss()
                }
            )
            .navigationTitle("\(subject.displayName)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            PhotoPicker(selectedImages: $viewModel.selectedImages)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showCamera) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: .camera)
                .ignoresSafeArea()
                .onChange(of: viewModel.selectedImage) { newImage in
                    if let image = newImage {
                        Task {
                            await viewModel.addImage(image)
                            await MainActor.run {
                                viewModel.selectedImage = nil
                            }
                        }
                    }
                }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK")) {
                    if viewModel.alertTitle == "Success" {
                        dismiss()
                    }
                }
            )
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - View Components
    private var imagesSectionFooter: some View {
        Text(viewModel.selectedImages.isEmpty ? "No images selected" : "\(viewModel.selectedImages.count) images selected")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private func imageCell(for index: Int) -> some View {
        VStack {
            Image(uiImage: viewModel.selectedImages[index])
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    Button(action: {
                        viewModel.removeImage(at: index)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(4),
                    alignment: .topTrailing
                )
        }
    }
    
    private var generateQuestionsButton: some View {
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

// MARK: - PhotoPicker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10 // 최대 10장까지 선택 가능
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                print("Image selection successful")
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - LoadingView
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(10)
        }
    }
}
