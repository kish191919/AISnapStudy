
import Foundation
import SwiftUI
import PhotosUI

class QuestionSettingsViewModel: ObservableObject {
    private let homeViewModel: HomeViewModel
    private let networkMonitor = NetworkMonitor.shared
    private var openAIService: OpenAIService?
    private let imageService = ImageService.shared
    private let totalMaximumQuestions = 20
    @Published var selectedImages: [UIImage] = []
    @Published var hasCameraImage: Bool = false
    @Published var hasGalleryImages: Bool = false
    @Published var questionText: String = ""
    @Published var isUsingTextInput: Bool = false
    @Published var isTextInputActive: Bool = false
    @Published var hasSelectedCamera: Bool = false    // Add this
    @Published var hasSelectedGallery: Bool = false   // Add this
    @Published var shouldCollapseQuestionTypes = false

    
    let subject: Subject
    
    // MARK: - Published Properties
    @Published var selectedSubject: Subject
    @Published var educationLevel: EducationLevel {
        didSet {
            print("📚 ViewModel - Education Level updated from \(oldValue) to \(educationLevel)")
        }
    }
    @Published var difficulty: Difficulty
    
    @Published var multipleChoiceCount: Int {
        didSet {
            print("ViewModel - Multiple Choice Count updated to: \(multipleChoiceCount)")
        }
    }
    @Published var fillInBlanksCount: Int {
        didSet {
            print("ViewModel - Fill in Blanks Count updated to: \(fillInBlanksCount)")
        }
    }
    @Published var matchingCount: Int {
        didSet {
            print("ViewModel - Matching Count updated to: \(matchingCount)")
        }
    }
    @Published var trueFalseCount: Int {
            didSet {
                print("ViewModel - True/False Count updated to: \(trueFalseCount)")
            }
        }
    
    @Published var isLoading: Bool
    @Published var error: Error?
    @Published var networkError: NetworkError?
    @Published var isNetworkAvailable: Bool
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var selectedImage: UIImage?
    @Published var showAlert: Bool
    @Published var alertTitle: String
    @Published var alertMessage: String
    
    // questionText가 비어있지 않으면 이미지 옵션을 숨기기 위한 계산 속성
    var shouldShowImageOptions: Bool {
        questionText.isEmpty && !hasCameraImage && !hasGalleryImages
    }
    
    // 텍스트 입력을 리셋하는 메서드
    func resetTextInput() {
        questionText = ""
        isUsingTextInput = false
    }
    
    // Update computed property
    var canUseTextInput: Bool {
        return selectedImages.isEmpty // 실제 선택된 이미지가 없을 때만 체크
    }
    
    func collapseQuestionTypes() {
        shouldCollapseQuestionTypes = true
        // 다음 상태 변경을 위해 리셋
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldCollapseQuestionTypes = false
        }
    }

    var canUseImageInput: Bool {
        return !isTextInputActive || questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func toggleTextInput() {
        isTextInputActive.toggle()
        if !isTextInputActive {
            questionText = ""
        }
    }
    
    func onImageOptionSelected() {
            shouldCollapseQuestionTypes = true
            // 상태 리셋
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.shouldCollapseQuestionTypes = false
            }
        }

    var totalQuestionCount: Int {
        multipleChoiceCount + fillInBlanksCount + matchingCount + trueFalseCount
    }
    
    func canAddMoreQuestions() -> Bool {
        return totalQuestionCount < totalMaximumQuestions
    }
    
    func remainingQuestions() -> Int {
        return totalMaximumQuestions - totalQuestionCount
    }
    
    // MARK: - Initialization
    init(subject: Subject, homeViewModel: HomeViewModel) {
        self.subject = subject
        self.homeViewModel = homeViewModel
        
        // Initialize all Published properties
        self.selectedSubject = subject
        self.educationLevel = .elementary
        self.difficulty = .medium
        self.multipleChoiceCount = 0
        self.fillInBlanksCount = 0
        self.matchingCount = 0
        
        self.isLoading = false
        self.networkError = nil
        self.isNetworkAvailable = true
        self.showImagePicker = false
        self.showCamera = false
        self.selectedImages = []
        self.showAlert = false
        self.alertTitle = ""
        self.alertMessage = ""
        self.trueFalseCount = 0
        self.selectedImages = [] 
        
        // After all properties are initialized, setup network monitoring
        self.isNetworkAvailable = networkMonitor.isReachable
        
        // Initialize OpenAI service
        do {
            self.openAIService = try OpenAIService()
        } catch {
            self.error = error
            print("Failed to initialize OpenAI service:", error)
        }
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        isNetworkAvailable = networkMonitor.isReachable
    }
    
    // MARK: - Public Methods
    func resetCounts() {
        multipleChoiceCount = 0
        fillInBlanksCount = 0
        matchingCount = 0
        trueFalseCount = 0
        hasCameraImage = false
        hasGalleryImages = false
    }
    
    var hasValidQuestionCount: Bool {
        multipleChoiceCount + fillInBlanksCount + matchingCount + trueFalseCount > 0
    }
    
    @MainActor
    func loadData() async {
        await homeViewModel.loadData()
    }
    
    // MARK: - Image Management
    @MainActor
    func addImage(_ image: UIImage) async {
        do {
            let compressedData = try await Task {
                try ImageCompressor.shared.compressForAPI(image)
            }.value
            
            if let compressedImage = UIImage(data: compressedData) {
                selectedImages.append(compressedImage)
                // Update button states after successfully adding image
                if hasCameraImage {
                    hasSelectedCamera = true
                }
                if hasGalleryImages {
                    hasSelectedGallery = true
                }
                print("Image added. Total images: \(selectedImages.count)")
            }
        } catch {
            self.error = error
            showError(error)
        }
    }
    

    func removeImage(at index: Int) {
        selectedImages.remove(at: index)
        if selectedImages.isEmpty {
            hasCameraImage = false
            hasGalleryImages = false
            isUsingTextInput = false
            hasSelectedCamera = false    // Reset states
            hasSelectedGallery = false   // Reset states
        }
    }
    
    @MainActor
    func sendAllImages() async {
        print("\n🚀 Starting sendAllImages")
        print("Current state:")
        print("• Selected Images: \(selectedImages.count)")
        print("• Question Text: \(questionText.isEmpty ? "Empty" : "Has content")")
        print("• Is Loading: \(isLoading)")
        
        // 입력 검증
        guard !selectedImages.isEmpty || !questionText.isEmpty else {
            print("❌ No content to generate questions from")
            return
        }
        
        // 네트워크 연결 확인
        guard networkMonitor.isReachable else {
            print("❌ No network connection")
            showError(NetworkError.noConnection as Error)
            return
        }
        
        isLoading = true
        print("🔄 Started loading state")
        
        do {
            if !selectedImages.isEmpty {
                print("📸 Processing \(selectedImages.count) images")
                for (index, image) in selectedImages.enumerated() {
                    print("🖼️ Processing image \(index + 1) of \(selectedImages.count)")
                    let compressedData = try await Task {
                        try ImageCompressor.shared.compressForAPI(image)
                    }.value
                    
                    await generateQuestions(from: compressedData, subject: subject)
                }
                
                selectedImages.removeAll()
                print("✅ All images processed and cleared")
            } else if !questionText.isEmpty {
                print("📝 Processing text input")
                // 텍스트 기반 문제 생성 로직
            }
            
            print("✅ Successfully generated questions")
            showSuccess()
        } catch {
            print("❌ Error in sendAllImages: \(error.localizedDescription)")
            self.error = error
            showError(error)
        }
        
        isLoading = false
        print("✅ Finished loading state\n")
    }
    
    // MARK: - Image Capture Methods
    @MainActor
    func takePhoto() async {
        print("📸 Taking photo...")
        do {
            let hasPermission = try await imageService.requestPermission(for: .camera)
            if hasPermission {
                showCamera = true
                hasCameraImage = true
            } else {
                self.error = ImageServiceError.permissionDenied
                showError(ImageServiceError.permissionDenied)
            }
        } catch {
            if let imageError = error as? ImageServiceError {
                showError(imageError)
            } else {
                showError(error)
            }
        }
    }
    
    @MainActor
    func handleCameraImage(_ image: UIImage?) {
        print("📸 Processing camera image...")
        guard let image = image else {
            print("❌ No image captured")
            return
        }

        Task {
            do {
                await addImage(image)
                hasCameraImage = true
                hasSelectedCamera = true
                print("✅ Camera image added successfully")
            } catch {
                print("❌ Failed to add camera image: \(error)")
                showError(error)
            }
        }
    }
     
     @MainActor
     func selectFromGallery() async {
         do {
             let hasPermission = try await imageService.requestPermission(for: .gallery)
             if hasPermission {
                 showImagePicker = true
                 hasGalleryImages = true
             } else {
                 self.error = ImageServiceError.permissionDenied
                 showError(ImageServiceError.permissionDenied)
             }
         } catch {
             if let imageError = error as? ImageServiceError {
                 showError(imageError)
             } else {
                 showError(error)
             }
         }
     }
    
    // MARK: - Question Generation
    @MainActor
       private func generateQuestions(from imageData: Data, subject: Subject) async {
           guard let openAIService = openAIService else {
               print("❌ OpenAI service not initialized")
               return
           }
           
           do {
               let questionTypes: [QuestionType: Int] = [
                   .multipleChoice: multipleChoiceCount,
                   .fillInBlanks: fillInBlanksCount,
                   .matching: matchingCount,
                   .trueFalse: trueFalseCount
               ].filter { $0.value > 0 }
               
               let questions = try await openAIService.generateQuestions(
                   from: imageData,
                   subject: subject,
                   difficulty: difficulty,
                   questionTypes: questionTypes
               )
               
               print("✅ Generated \(questions.count) questions")
               await processGeneratedQuestions(questions)
           } catch {
               print("❌ Question generation error: \(error)")
               self.error = error
               showError(error)
           }
       }
    
    @MainActor
    func processGeneratedQuestions(_ questions: [Question]) async {
        print("\n🔄 Processing Generated Questions:")
        print("Number of questions by type:")
        let questionsByType = Dictionary(grouping: questions, by: { $0.type })
        questionsByType.forEach { type, questions in
            print("- \(type.rawValue): \(questions.count) questions")
        }
        
        let subject = questions.first?.subject ?? self.subject
        let problemSet = ProblemSet(
            id: UUID().uuidString,
            title: "Generated Questions",
            subject: subject,
            difficulty: difficulty,
            questions: questions,
            createdAt: Date()
        )
        
        print("\n📦 Setting ProblemSet in HomeViewModel")
        // ProblemSet 저장
        await homeViewModel.saveProblemSet(problemSet)
        // 저장된 ProblemSet을 바로 선택하여 사용
        await homeViewModel.setSelectedProblemSet(problemSet)
        
        // Study 탭으로 자동 전환
        NotificationCenter.default.post(
            name: Notification.Name("ShowStudyView"),
            object: nil
        )
    }

    @MainActor
    private func showSuccess() {
        alertTitle = "Success"
        alertMessage = "Questions have been successfully generated."
        showAlert = true
        
        // Success alert가 표시된 후 Study 탭으로 전환하기 위한 notification 발송
        NotificationCenter.default.post(
            name: Notification.Name("ShowStudyView"),
            object: nil
        )
    }
    
    
    // MARK: - Error Handling
    @MainActor
    private func showError(_ error: Error) {
        print("Error details:", error.localizedDescription)
        
        if let networkError = error as? NetworkError {
            alertTitle = "Network Error"
            alertMessage = networkError.errorDescription ?? "A network error occurred"
        } else if let imageError = error as? ImageServiceError {
            switch imageError {
            case .permissionDenied:
                alertTitle = "Permission Required"
                alertMessage = """
                    Camera or photo library access is not authorized.
                    Please enable access in Settings.
                    
                    Go to: Settings > Privacy > Camera/Photos
                    """
            case .unavailable:
                alertTitle = "Feature Unavailable"
                alertMessage = "This feature is not available on your device."
            case .compressionFailed:
                alertTitle = "Image Processing Error"
                alertMessage = "Failed to process the image. Please try another image."
            case .unknown(let underlyingError):
                alertTitle = "Unknown Error"
                alertMessage = "An unexpected error occurred: \(underlyingError.localizedDescription)"
            }
        } else {
            alertTitle = "Error"
            alertMessage = """
                An error occurred. Please try again.
                Error: \(error.localizedDescription)
                """
        }
        showAlert = true
    }
    
}

extension QuestionSettingsViewModel {
    @MainActor
    func selectMultiplePhotos() {
        showImagePicker = true
    }
}
