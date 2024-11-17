

import SwiftUI
import PhotosUI
import UIKit

struct QuestionSettingsView: View {
    @StateObject private var viewModel: QuestionSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    @State private var expandedSections: Set<SectionType> = []
    @State private var isTextInputSelected = false
    @State private var showNamePopup = false
    @State private var isGeneratingQuestions = false
    
    let subject: Subject
    
    public enum SectionType: Hashable {
        case questionAbout
        case learningSubject
        case questionTypes
        case educationLevel
        case difficultyLevel
    }
    
    init(subject: Subject, homeViewModel: HomeViewModel, selectedTab: Binding<Int>) {
        self.subject = subject
        self._viewModel = StateObject(wrappedValue: QuestionSettingsViewModel(
            subject: subject,
            homeViewModel: homeViewModel
        ))
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                // Question About Section
                // 기존 코드 중복 호출 확인
                Section {
                    DisclosureGroup(
                        isExpanded: .constant(true)
                    ) {
                        // ✅ 중복 확인 후 하나만 남기기
                        QuestionAboutSection(
                            viewModel: viewModel,
                            isTextInputSelected: $isTextInputSelected
                        )
                    } label: {
                        HStack {
                            Text("Question About")
                                .font(.headline)
                            Spacer()
                            if !viewModel.selectedImages.isEmpty {
                                Text("\(viewModel.selectedImages.count) selected")
                                    .foregroundColor(.green)
                            } else if !viewModel.questionText.isEmpty {
                                Text("Text input")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }.listRowSpacing(0)

                
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
                }.listRowSpacing(0)
                
                // Question Types Section
                Section {
                    DisclosureGroup(
                        isExpanded: isExpandedBinding(for: .questionTypes)
                    ) {
                        QuestionTypesSelectionSection(viewModel: viewModel)
                    } label: {
                        HStack {
                            Text("Question Types")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.totalQuestionCount) questions")
                                .foregroundColor(.gray)
                        }
                    }
                }.listRowSpacing(0)
                
                if isTextInputSelected {
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
                    }.listRowSpacing(0)
                    
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
                    }.listRowSpacing(0)
                }
            }
            .listSectionSpacing(4)
            
            // Generate Questions Button
            VStack {
                Button(action: {
                    showNamePopup = true
                    isGeneratingQuestions = true
                    Task {
                        await viewModel.sendAllImages()
                    }
                }) {
                    Text("Generate Questions")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isGenerateButtonEnabled ? Color.accentColor : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isGenerateButtonEnabled)
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .overlay(popupOverlay)
        .navigationBarItems(leading: cancelButton)
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
        .onChange(of: viewModel.shouldShowStudyView) { show in
            if show {
                dismiss()
                selectedTab = 1
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            viewModel.resetCounts()
            dismiss()
        }
    }
    
    private var popupOverlay: some View {
        Group {
            if showNamePopup {
                ProblemSetNamePopup(
                    isPresented: $showNamePopup,
                    problemSetName: $viewModel.problemSetName,
                    isGeneratingQuestions: $viewModel.isGeneratingQuestions,
                    defaultName: viewModel.generateDefaultName()
                ) {
                    viewModel.saveProblemSetName()
                    showNamePopup = false
                    viewModel.shouldShowStudyView = true
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showNamePopup)
            }
        }
    }
    
    private var isGenerateButtonEnabled: Bool {
        let hasInput = !viewModel.selectedImages.isEmpty ||
            (!viewModel.questionText.isEmpty && viewModel.isTextInputActive)
        let hasQuestionType = viewModel.totalQuestionCount > 0
        return hasInput && hasQuestionType
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



struct GeneratingQuestionsOverlay: View {
    let questionCount: Int
    @State private var animatingDots = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Generating \(questionCount) questions\(dots)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Please wait...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(10)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever()) {
                animatingDots.toggle()
            }
        }
    }
    
    private var dots: String {
        animatingDots ? "..." : ""
    }
}

struct ProblemSetNamePopup: View {
    @Binding var isPresented: Bool
    @Binding var problemSetName: String
    @Binding var isGeneratingQuestions: Bool  // 추가
    let defaultName: String
    let onSubmit: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Text("Name Your Question Set")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter a name for your question set:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter name", text: $problemSetName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .frame(height: 44)
                        .placeholder(when: problemSetName.isEmpty) {
                            Text("Default: \(defaultName)")
                                .foregroundColor(.gray)
                        }
                }
                
                // 질문 생성 상태에 따른 메시지 표시
                Text(isGeneratingQuestions ?
                     "Questions are being generated... Please wait." :
                     "Questions are ready. Please save the name to continue.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    if problemSetName.isEmpty {
                        problemSetName = defaultName
                    }
                    if !isGeneratingQuestions {
                        onSubmit()
                    }
                }) {
                    Text(isGeneratingQuestions ? "Generating Questions..." : "Save Name")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isGeneratingQuestions ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isGeneratingQuestions)
            }
            .padding(32)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 32)
        }
    }
}

// Generate Questions Footer
struct GenerateQuestionsFooter: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    @Binding var isGeneratingQuestions: Bool
    @Binding var showNamePopup: Bool
    let isGenerateButtonEnabled: Bool
    
    var body: some View {
        VStack {
            Button(action: {
                showNamePopup = true
                isGeneratingQuestions = true
                Task {
                    await viewModel.sendAllImages()
                }
            }) {
                Text("Generate Questions")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isGenerateButtonEnabled ? Color.accentColor : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!isGenerateButtonEnabled)
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct LoadingOverlay: View {
    var body: some View {
        LoadingView()
            .frame(maxHeight: 120)
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
            .padding()
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
                    Text("Total: \(viewModel.totalQuestionCount)/10")
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
                            print("Selected subject: \(subject.rawValue)")  // 로깅 추가
                        }
                    }
                }
                .padding(.vertical, 8)
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



