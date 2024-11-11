
// File: ./AISnapStudy/Views/Question/QuestionSettingsView.swift

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
        Form {
            LearningSubjectSection(selectedSubject: $viewModel.selectedSubject)
            EducationLevelSelectionSection(selectedLevel: $viewModel.educationLevel)
            DifficultyLevelSection(difficulty: $viewModel.difficulty)
            QuestionTypesSelectionSection(viewModel: viewModel)
            
            if viewModel.hasValidQuestionCount {
                ImageSelectionSection(viewModel: viewModel)
            } else {
                EmptyQuestionSection()
            }
        }
        .navigationBarItems(
            leading: Button("Cancel") {
                viewModel.resetCounts()
                dismiss()
            }
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section Views
// File: ./AISnapStudy/Views/Question/QuestionSettingsView.swift

struct LearningSubjectSection: View {
    @Binding var selectedSubject: Subject
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        Section("Learning Subject") {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Subject.allCases, id: \.self) { subject in
                    SubjectSelectionButton(
                        subject: subject,
                        isSelected: selectedSubject == subject
                    ) {
                        withAnimation(.spring()) {
                            selectedSubject = subject
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// SubjectSelectionButton도 함께 수정
struct SubjectSelectionButton: View {
    let subject: Subject
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: subject.icon)
                    .font(.system(size: 24))
                Text(subject.displayName)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? subject.color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? subject.color : .gray)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? subject.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}



// File: ./AISnapStudy/Views/Question/QuestionSettingsView.swift

// 2. EducationLevelSelectionSection 수정
struct EducationLevelSelectionSection: View {
    @Binding var selectedLevel: EducationLevel
    
    var body: some View {
        Section("Education Level") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(EducationLevel.allCases, id: \.self) { level in
                    SelectableButton(
                        title: level.displayName,
                        isSelected: selectedLevel == level,
                        color: level.color
                    ) {
                        print("Selected level: \(level)")
                        selectedLevel = level
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// SelectableButton은 이미 있는 것을 사용
struct SelectableButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? color : .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultyLevelSection: View {
    @Binding var difficulty: Difficulty
    
    var body: some View {
        Section("Difficulty Level") {
            HStack(spacing: 12) {
                ForEach(Difficulty.allCases, id: \.self) { level in
                    SelectableButton(
                        title: level.displayName,
                        isSelected: difficulty == level,
                        color: level.color
                    ) {
                        withAnimation(.spring()) {
                            difficulty = level
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct QuestionTypesSelectionSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
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
                QuestionTypeCounter(
                    title: "True or False",
                    count: $viewModel.trueFalseCount
                )
            }
        }
    }
}

struct EmptyQuestionSection: View {
    var body: some View {
        Section {
            Text("Please select at least one question type")
                .foregroundColor(.secondary)
                .font(.footnote)
        }
    }
}

struct EducationLevelButton: View {
    let level: EducationLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(level.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? level.color.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? level.color : .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
                )
        }
    }
}

// Subject Selection Section
struct SubjectSelectionSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        Section("Learning Subject") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Subject.allCases, id: \.self) { subject in
                        SubjectSelectionButton(
                            subject: subject,
                            isSelected: viewModel.selectedSubject == subject
                        ) {
                            viewModel.selectedSubject = subject
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

// Education Level Section
struct EducationLevelSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        Section("Education Level") {
            HStack(spacing: 12) {
                ForEach(EducationLevel.allCases, id: \.self) { level in
                    EducationLevelButton(
                        level: level,
                        isSelected: viewModel.educationLevel == level
                    ) {
                        viewModel.educationLevel = level
                    }
                }
            }
        }
    }
}

// Difficulty Section
struct DifficultySection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        Section("Difficulty Level") {
            Picker("Difficulty", selection: $viewModel.difficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.rawValue.capitalized)
                        .tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// Question Types Section
struct QuestionTypesSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
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
    }
}


// ImagePicker, PhotoPicker, LoadingView 도 추가
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10
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

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
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
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

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
