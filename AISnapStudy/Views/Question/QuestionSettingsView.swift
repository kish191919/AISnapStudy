
// Views/Question/QuestionSettingsView.swift
import SwiftUI
import PhotosUI

struct QuestionSettingsView: View {
    let subject: Subject
    @StateObject private var viewModel: QuestionSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode

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
                
                // Image Selection
                if viewModel.hasValidQuestionCount {
                    Section("Select Image") {
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
                    dismiss()
                }
            )
            .navigationTitle("\(subject.displayName)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: .photoLibrary)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showCamera) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: .camera)
                .ignoresSafeArea()
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
    }
}

// ImagePicker struct
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

// LoadingView struct
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

