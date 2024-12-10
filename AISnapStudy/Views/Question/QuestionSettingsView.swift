

import SwiftUI
import PhotosUI
import UIKit
import AVFoundation

struct QuestionSettingsView: View {
    @FocusState private var isTextFieldFocused: Bool // 추가
    @StateObject private var viewModel: QuestionSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    @State private var expandedSections: Set<SectionType> = []
    @State private var isTextInputSelected = false
    @State private var showNamePopup = false
    @State private var isGeneratingQuestions = false
    @State private var activeSheet: ActiveSheet?
    
    // 여기를 Subject에서 DefaultSubject로 변경
    let subject: DefaultSubject  // Subject를 DefaultSubject로 변경
    
    public enum SectionType: Hashable {
        case questionAbout
        case learningSubject
        case questionTypes
        case educationLevel
    }
    
    private enum ActiveSheet: Identifiable {
        case camera, gallery
        
        var id: Int {
            switch self {
            case .camera: return 1
            case .gallery: return 2
            }
        }
    }
    
    
    init(subject: DefaultSubject, homeViewModel: HomeViewModel, selectedTab: Binding<Int>) {
        self.subject = subject
        self._viewModel = StateObject(wrappedValue: QuestionSettingsViewModel(
            subject: subject,
            homeViewModel: homeViewModel
        ))
        self._selectedTab = selectedTab
    }

    var body: some View {
        VStack(spacing: 0) {
            // Instructions Card
            Form {
                // Speed Up and Language Selection Section
                Section {
                    SpeedUpSection(useTextExtraction: $viewModel.useTextExtraction)
                }
                .listRowSpacing(0)

                Section {
                    LanguageSection(selectedLanguage: $viewModel.selectedLanguage)
                }
                .listRowSpacing(0)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("How to Generate Questions")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Text("Select one of these methods here and then choose Subject and Type to create questions:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Input Methods with descriptions
                    HStack(spacing: 12) {
                        Group {
                            InputMethodCard(
                                icon: "camera.fill",
                                title: "Camera",
                                isUsed: viewModel.hasSelectedCamera,
                                isDisabled: !viewModel.canUseImageInput,
                                action: {
                                    if viewModel.canUseImageInput {
                                        viewModel.isTextInputActive = false
                                        Task {
                                            if await viewModel.checkCameraPermission() {
                                                activeSheet = .camera
                                            }
                                        }
                                    }
                                }
                            )
                            .frame(maxWidth: .infinity)
                        }
                        
                        Group {
                            InputMethodCard(
                                icon: "photo.fill",
                                title: "Gallery",
                                isUsed: viewModel.hasSelectedGallery,
                                isDisabled: !viewModel.canUseImageInput,
                                action: {
                                    if viewModel.canUseImageInput {
                                        viewModel.isTextInputActive = false
                                        Task {
                                            if await viewModel.checkGalleryPermission() {
                                                activeSheet = .gallery
                                            }
                                        }
                                    }
                                }
                            )
                            .frame(maxWidth: .infinity)
                        }
                        
                        Group {
                            InputMethodCard(
                                icon: "text.bubble.fill",
                                title: "Text",
                                isUsed: viewModel.isTextInputActive,
                                isDisabled: !viewModel.canUseTextInput,
                                action: {
                                    viewModel.toggleTextInput()
                                    isTextFieldFocused = viewModel.isTextInputActive
                                }
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Text Input Field
                if viewModel.isTextInputActive {
                    TextField("Enter your question here...", text: $viewModel.questionText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .padding(.horizontal)
                }

                // Selected Images Display
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
                
                // Subject Section
                Section {
                    DisclosureGroup(
                        isExpanded: isExpandedBinding(for: .learningSubject)
                    ) {
                        LearningSubjectSection(selectedSubject: $viewModel.selectedSubject)
                    } label: {
                        HStack {
                            Text("Subject")
                                .font(.headline)
                            Spacer()
                            Text(viewModel.selectedSubject.displayName)
                                .foregroundColor(.gray)
                        }
                    }
                }.listRowSpacing(0)
                
                if viewModel.isTextInputActive {
                    Section {
                        DisclosureGroup(
                            isExpanded: isExpandedBinding(for: .educationLevel)
                        ) {
                            EducationLevelSelectionSection(selectedLevel: $viewModel.educationLevel)
                        } label: {
                            HStack {
                                Text("Education")
                                    .font(.headline)
                                Spacer()
                                Text(viewModel.educationLevel.displayName)
                                    .foregroundColor(.gray)
                            }
                        }
                    }.listRowSpacing(0)
                }
                
                // Question Types Section
                Section {
                    DisclosureGroup(
                        isExpanded: isExpandedBinding(for: .questionTypes)
                    ) {
                        QuestionTypesSelectionSection(viewModel: viewModel)
                    } label: {
                        HStack {
                            Text("Type")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.totalQuestionCount) questions")
                                .foregroundColor(.gray)
                        }
                    }
                }.listRowSpacing(0)
            }
            .listSectionSpacing(4)
            
            // Generate Questions Button and Keyboard Dismiss Button
            VStack {
                HStack {
                    Button(action: {
                        showNamePopup = true
                        isGeneratingQuestions = true
                        isTextFieldFocused = false  // 키보드 내리기
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
                    
                    // 텍스트 입력이 활성화되어 있을 때만 키보드 내리기 버튼 표시
                    if viewModel.isTextInputActive {
                        Button(action: {
                            isTextFieldFocused = false  // 키보드 내리기
                        }) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .overlay(popupOverlay)
        .navigationBarItems(leading: cancelButton)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .camera:
                ImagePicker(
                    image: $viewModel.selectedImage,
                    sourceType: .camera,
                    onImageSelected: { image in
                        Task {
                            await viewModel.handleCameraImage(image)
                        }
                    }
                )
                .interactiveDismissDisabled()
                
            case .gallery:
                PhotoPicker(selectedImages: $viewModel.selectedImages)
                    .interactiveDismissDisabled()
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
        .onChange(of: viewModel.shouldShowStudyView) { show in
            if show {
                dismiss()
                selectedTab = 1
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




struct ProblemSetNamePopup: View {
    @Binding var isPresented: Bool
    @Binding var problemSetName: String
    @Binding var isGeneratingQuestions: Bool
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
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 32)
        }
        // 불필요한 onChange나 onReceive 모디파이어 제거
    }
}

struct SubjectSelectionButton: View {
    let subject: any SubjectType
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
                    Text("Type")
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
    @StateObject private var subjectManager = SubjectManager.shared
    
    var body: some View {
        Section("Subject") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 기본 과목
                    ForEach(DefaultSubject.allCases, id: \.self) { subject in
                        SubjectSelectionButton(
                            subject: subject,
                            isSelected: viewModel.selectedSubject.id == subject.id
                        ) {
                            viewModel.selectedSubject = subject
                            print("Selected subject: \(subject.rawValue)")
                        }
                    }
                    
                    // 사용자 정의 과목
                    ForEach(subjectManager.customSubjects.filter { $0.isActive }) { subject in
                        SubjectSelectionButton(
                            subject: subject,
                            isSelected: viewModel.selectedSubject.id == subject.id
                        ) {
                            viewModel.selectedSubject = subject
                            print("Selected custom subject: \(subject.name)")
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

class CustomImagePickerController: UIImagePickerController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all // 모든 방향 지원
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    var onImageSelected: ((UIImage) -> Void)?
    
    class CustomImagePickerController: UIImagePickerController {
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait // 카메라 UI는 항상 세로 모드로 유지
        }
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = CustomImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        
        if sourceType == .camera {
            picker.cameraDevice = .rear
            picker.cameraCaptureMode = .photo
            picker.allowsEditing = false
            
            // 전체 화면 모드로 설정
            picker.modalPresentationStyle = .fullScreen
            
            // 카메라 UI를 세로 모드로 고정
            picker.navigationController?.navigationBar.isHidden = false
            picker.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
        
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
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                // 이미지는 원래 방향 그대로 유지
                parent.image = image
                parent.onImageSelected?(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// UIImage extension for orientation fixing
extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi/2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi/2)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        guard let cgImage = self.cgImage else { return self }
        
        let context = CGContext(data: nil,
                              width: Int(size.width),
                              height: Int(size.height),
                              bitsPerComponent: cgImage.bitsPerComponent,
                              bytesPerRow: 0,
                              space: cgImage.colorSpace!,
                              bitmapInfo: cgImage.bitmapInfo.rawValue)!
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = context.makeImage() else { return self }
        return UIImage(cgImage: newCGImage)
    }
}

struct InputMethodCard: View {
    let icon: String
    let title: String
    let isUsed: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.headline)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUsed ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isUsed ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}
