
// File: ./AISnapStudy/Views/Question/QuestionSettingsView.swift

import SwiftUI
import PhotosUI
import UIKit

struct QuestionSettingsView: View {
    let subject: Subject
    @StateObject private var viewModel: QuestionSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var expandedSections: Set<SectionType> = []
    
    // 섹션 타입을 정의
    enum SectionType {
        case learningSubject
        case educationLevel
        case difficultyLevel
        case questionTypes
    }
    
    init(subject: Subject, homeViewModel: HomeViewModel) {
        self.subject = subject
        self._viewModel = StateObject(wrappedValue: QuestionSettingsViewModel(subject: subject, homeViewModel: homeViewModel))
    }
    
    var body: some View {
        Form {
            Group {
                // Learning Subject Section
                Section {
                    DisclosureGroup(
                        isExpanded: isExpandedBinding(for: .learningSubject)
                    ) {
                        LearningSubjectSection(selectedSubject: $viewModel.selectedSubject)
                    } label: {
                        HStack {
                            Text("Learning Subject")
                                .font(.headline)
                            Spacer()
                            Text(viewModel.selectedSubject.displayName)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listRowSpacing(0)
                
                // Education Level Section
                Section {
                    DisclosureGroup(
                        isExpanded: isExpandedBinding(for: .educationLevel)
                    ) {
                        EducationLevelSelectionSection(selectedLevel: $viewModel.educationLevel)
                    } label: {
                        HStack {
                            Text("Education Level")
                                .font(.headline)
                            Spacer()
                            Text(viewModel.educationLevel.displayName)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listRowSpacing(0)
              
                // Difficulty Level Section
                Section {
                    DisclosureGroup(
                        isExpanded: isExpandedBinding(for: .difficultyLevel)
                    ) {
                        DifficultyLevelSection(difficulty: $viewModel.difficulty)
                    } label: {
                        HStack {
                            Text("Difficulty Level")
                                .font(.headline)
                            Spacer()
                            Text(viewModel.difficulty.displayName)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listRowSpacing(0)
                
                // Question Types Section
                Section {
                    DisclosureGroup(
                        isExpanded: isExpandedBinding(for: .questionTypes)
                    ) {
                        VStack(spacing: 8) {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                QuestionTypeCard(
                                    viewModel: viewModel,
                                    title: "Multiple",
                                    icon: "list.bullet.circle.fill",
                                    count: $viewModel.multipleChoiceCount
                                )
                                
                                QuestionTypeCard(
                                    viewModel: viewModel,
                                    title: "Fill in Blanks",
                                    icon: "square.and.pencil",
                                    count: $viewModel.fillInBlanksCount
                                )
                                
                                QuestionTypeCard(
                                    viewModel: viewModel,
                                    title: "True/False",
                                    icon: "checkmark.circle.fill",
                                    count: $viewModel.trueFalseCount
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    } label: {
                        HStack {
                            Text("Question Types")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.totalQuestionCount) questions")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listRowSpacing(0)
            }
            .listSectionSpacing(8)
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
        .sheet(isPresented: $viewModel.showImagePicker) {
            PhotoPicker(selectedImages: $viewModel.selectedImages)
        }
        .sheet(isPresented: $viewModel.showCamera) {
            ImagePicker(
                image: $viewModel.selectedImage,
                sourceType: .camera,
                onImageSelected: { image in
                    Task {
                        await viewModel.handleCameraImage(image)
                    }
                }
            )
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
        .onChange(of: viewModel.shouldCollapseQuestionTypes) { shouldCollapse in
            if shouldCollapse {
                withAnimation {
                    expandedSections.remove(.questionTypes)
                }
            }
        }
    }
    
    private func isExpandedBinding(for section: SectionType) -> Binding<Bool> {
        Binding(
            get: { expandedSections.contains(section) },
            set: { isExpanded in
                withAnimation {
                    if isExpanded {
                        expandedSections.insert(section)
                    } else {
                        expandedSections.remove(section)
                    }
                }
            }
        )
    }
}


struct LearningSubjectSection: View {
   @Binding var selectedSubject: Subject
   
   let columns = [
       GridItem(.flexible()),
       GridItem(.flexible()),
       GridItem(.flexible())
   ]
   
   var body: some View {
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

struct EducationLevelSelectionSection: View {
   @Binding var selectedLevel: EducationLevel
   
   var body: some View {
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
                   selectedLevel = level
               }
           }
       }
       .padding(.vertical, 8)
   }
}

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


struct QuestionTypeCard: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel  // 추가
    let title: String
    let icon: String
    @Binding var count: Int
    let maximum: Int = 10
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon and Title
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(count > 0 ? .green : .gray)
                Text(title)
                    .font(.headline)
                    .foregroundColor(count > 0 ? .green : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            
            // Counter with total count
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Button {
                        if count > 0 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                count -= 1
                                HapticManager.shared.impact(style: .light)
                            }
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(count > 0 ? .green : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Text("\(count)")
                        .font(.title2.bold())
                        .foregroundColor(count > 0 ? .green : .gray)
                        .frame(minWidth: 30)
                    
                    Button {
                        if count < maximum && viewModel.canAddMoreQuestions() {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                count += 1
                                HapticManager.shared.impact(style: .light)
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(
                                (count < maximum && viewModel.canAddMoreQuestions()) ? .green : .gray
                            )
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(count > 0 ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(count > 0 ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

// QuestionTypesSelectionSection도 수정
struct QuestionTypesSelectionSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        Section {
            VStack(spacing: 8) {
                // 총 문제 수 표시
                HStack {
                    Text("Question Types")
                        .font(.headline)
                    Spacer()
                    Text("Total: \(viewModel.totalQuestionCount)/20")
                        .font(.subheadline)
                        .foregroundColor(viewModel.totalQuestionCount > 0 ? .green : .gray)
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 12) {
                    QuestionTypeCard(
                        viewModel: viewModel,
                        title: "Multiple",
                        icon: "list.bullet.circle.fill",
                        count: $viewModel.multipleChoiceCount
                    )
                    
                    QuestionTypeCard(
                        viewModel: viewModel,
                        title: "Fill in Blanks",
                        icon: "square.and.pencil",
                        count: $viewModel.fillInBlanksCount
                    )
                    
                    QuestionTypeCard(
                        viewModel: viewModel,
                        title: "True/False",
                        icon: "checkmark.circle.fill",
                        count: $viewModel.trueFalseCount
                    )
                }
            }
            .padding(.vertical, 8)
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
                    title: "Multiple",
                    count: $viewModel.multipleChoiceCount
                )
                
                QuestionTypeCounter(
                    title: "Fill in the Blanks",
                    count: $viewModel.fillInBlanksCount
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
    var onImageSelected: ((UIImage) -> Void)? // 추가
    
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
                parent.onImageSelected?(image)  // 콜백 호출
                print("📸 Image captured successfully")
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📸 Camera capture cancelled")
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





