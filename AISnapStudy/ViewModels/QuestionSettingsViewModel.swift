
import Foundation
import SwiftUI
import PhotosUI

@MainActor
class QuestionSettingsViewModel: ObservableObject {
    private let homeViewModel: HomeViewModel
    private let networkMonitor = NetworkMonitor.shared
    private let imageService = ImageService.shared
    private var openAIService: OpenAIService?
    private let totalMaximumQuestions = 10
    private var studyViewModel: StudyViewModel? // 추가
    
    // UserDefaults keys
    private enum UserDefaultsKeys {
        static let lastSubject = "lastSelectedSubject"
        static let lastEducationLevel = "lastEducationLevel"
        static let lastDifficulty = "lastDifficulty"
        static let lastMultipleChoiceCount = "lastMultipleChoiceCount"
        static let lastFillInBlanksCount = "lastFillInBlanksCount"
        static let lastTrueFalseCount = "lastTrueFalseCount"
    }
    
    @Published var selectedImages: [UIImage] = []
    @Published var hasCameraImage: Bool = false
    @Published var hasGalleryImages: Bool = false
    @Published var questionText: String = ""
    @Published var isUsingTextInput: Bool = false
    @Published var isTextInputActive: Bool = false
    @Published var hasSelectedCamera: Bool = false
    @Published var hasSelectedGallery: Bool = false
    @Published var shouldCollapseQuestionTypes = false
    @Published var shouldShowStudyView = false
    @Published var problemSetName: String = ""
    
    let subject: Subject
    
    // MARK: - Published Properties with UserDefaults persistence
     @Published var selectedSubject: Subject {
         didSet {
             UserDefaults.standard.set(selectedSubject.rawValue, forKey: UserDefaultsKeys.lastSubject)
         }
     }
     
     @Published var educationLevel: EducationLevel {
         didSet {
             UserDefaults.standard.set(educationLevel.rawValue, forKey: UserDefaultsKeys.lastEducationLevel)
             print("📚 ViewModel - Education Level updated from \(oldValue) to \(educationLevel)")
         }
     }
     
     @Published var difficulty: Difficulty {
         didSet {
             UserDefaults.standard.set(difficulty.rawValue, forKey: UserDefaultsKeys.lastDifficulty)
         }
     }
     
     @Published var multipleChoiceCount: Int {
         didSet {
             UserDefaults.standard.set(multipleChoiceCount, forKey: UserDefaultsKeys.lastMultipleChoiceCount)
             print("ViewModel - Multiple Choice Count updated to: \(multipleChoiceCount)")
         }
     }
     
     @Published var fillInBlanksCount: Int {
         didSet {
             UserDefaults.standard.set(fillInBlanksCount, forKey: UserDefaultsKeys.lastFillInBlanksCount)
             print("ViewModel - Fill in Blanks Count updated to: \(fillInBlanksCount)")
         }
     }
     
     
     @Published var trueFalseCount: Int {
         didSet {
             UserDefaults.standard.set(trueFalseCount, forKey: UserDefaultsKeys.lastTrueFalseCount)
             print("ViewModel - True/False Count updated to: \(trueFalseCount)")
         }
     }
     
     
     
     // MARK: - Initialization
    @MainActor
     init(subject: Subject, homeViewModel: HomeViewModel) {
         self.subject = subject
         self.homeViewModel = homeViewModel
         self.studyViewModel = homeViewModel.studyViewModel
         
         // Load last used values from UserDefaults
         let lastSubjectRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastSubject)
         let lastEducationLevelRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastEducationLevel)
         let lastDifficultyRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastDifficulty)
         
         // Initialize with last used values or defaults
         self.selectedSubject = Subject(rawValue: lastSubjectRaw ?? "") ?? subject
         self.educationLevel = EducationLevel(rawValue: lastEducationLevelRaw ?? "") ?? .elementary
         self.difficulty = Difficulty(rawValue: lastDifficultyRaw ?? "") ?? .medium
         
         // Load last question counts
         self.multipleChoiceCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.lastMultipleChoiceCount)
         self.fillInBlanksCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.lastFillInBlanksCount)
         self.trueFalseCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.lastTrueFalseCount)
         
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
    
    // 기본 이름 생성 메서드
    func generateDefaultName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMdd_HHmm"
        let dateString = dateFormatter.string(from: Date())
        let totalQuestions = multipleChoiceCount + fillInBlanksCount + trueFalseCount
        
        return "\(selectedSubject.displayName)_\(totalQuestions)Q_\(dateString)"
        // 예: "Math_10Q_0515_1430"
    }
     
     // 기존 resetCounts 메서드 수정
     func resetCounts() {
         // Reset counts without clearing UserDefaults
         multipleChoiceCount = 0
         fillInBlanksCount = 0
         trueFalseCount = 0
         hasCameraImage = false
         hasGalleryImages = false
     }
     
     // UserDefaults 완전 초기화가 필요한 경우를 위한 새로운 메서드
     func resetAllSettings() {
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastSubject)
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastEducationLevel)
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastDifficulty)
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastMultipleChoiceCount)
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastFillInBlanksCount)
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastTrueFalseCount)
         
         // Reset to defaults
         selectedSubject = subject
         educationLevel = .elementary
         difficulty = .medium
         resetCounts()
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
        multipleChoiceCount + fillInBlanksCount + trueFalseCount
    }
    
    func canAddMoreQuestions() -> Bool {
        return totalQuestionCount < totalMaximumQuestions
    }
    
    func remainingQuestions() -> Int {
        return totalMaximumQuestions - totalQuestionCount
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        isNetworkAvailable = networkMonitor.isReachable
    }
    
    var hasValidQuestionCount: Bool {
        multipleChoiceCount + fillInBlanksCount + trueFalseCount > 0
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
                try ImageService.shared.compressForAPI(image)
            }.value
            
            if let compressedImage = UIImage(data: compressedData) {
                selectedImages.append(compressedImage)
                if hasCameraImage {
                    hasSelectedCamera = true
                }
                if hasGalleryImages {
                    hasSelectedGallery = true
                }
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
       print("• Selected Subject: \(selectedSubject.displayName)")
       print("• Selected Images: \(selectedImages.count)")
       print("• Question Text: \(questionText.isEmpty ? "Empty" : "Has content")")
       print("• Is Loading: \(isLoading)")
       
       guard !selectedImages.isEmpty || !questionText.isEmpty else {
           print("❌ No content to generate questions from")
           return
       }
       
       guard networkMonitor.isReachable else {
           print("❌ No network connection")
           showError(NetworkError.noConnection as Error)
           return
       }
       
       // OpenAI로 데이터 전송 시 LoadingView 표시
       isLoading = true
       print("🔄 Started loading state")
       
       do {
           let questionTypes: [QuestionType: Int] = [
               .multipleChoice: multipleChoiceCount,
               .fillInBlanks: fillInBlanksCount,
               .trueFalse: trueFalseCount
           ].filter { $0.value > 0 }
           
           let parameters = OpenAIService.QuestionParameters(
               subject: selectedSubject,
               difficulty: difficulty,
               educationLevel: educationLevel,
               questionTypes: questionTypes
           )
           
           if problemSetName.isEmpty {
               problemSetName = generateDefaultName()
           }
           
           print("""
           📝 Question Generation Parameters:
           • Subject: \(selectedSubject.displayName)
           • Difficulty: \(difficulty.displayName)
           • Education Level: \(educationLevel.displayName)
           • Question Types: \(questionTypes.map { "- \($0.key.rawValue): \($0.value)" }.joined(separator: "\n"))
           """)
           
           // 데이터 전송이 완료되면 LoadingView를 숨기고
           // StudyView의 질문 생성 진행 상태 표시 시작
           isLoading = false
           studyViewModel?.isGeneratingQuestions = true
           
           if !selectedImages.isEmpty {
               print("📸 Processing \(selectedImages.count) images")
               for (index, image) in selectedImages.enumerated() {
                   print("🖼️ Processing image \(index + 1) of \(selectedImages.count)")
                   let compressedData = try await Task {
                       try ImageService.shared.compressForAPI(image)
                   }.value
                   
                   let input = OpenAIService.QuestionInput(
                       content: compressedData,
                       isImage: true
                   )
                   
                   await generateQuestions(from: input, parameters: parameters)
               }
               selectedImages.removeAll()
               print("✅ All images processed and cleared")
           } else if !questionText.isEmpty {
               print("📝 Processing text input: \(questionText)")
               guard let textData = questionText.data(using: .utf8) else {
                   throw NetworkError.invalidData
               }
               let input = OpenAIService.QuestionInput(
                   content: textData,
                   isImage: false
               )
               
               await generateQuestions(from: input, parameters: parameters)
               print("✅ Text input processed")
           }
           
           // 질문 생성이 완료되면 진행 상태 표시 종료
           studyViewModel?.isGeneratingQuestions = false
           print("✅ Successfully generated questions")
           showSuccess()
           
           // Study View로 전환
           shouldShowStudyView = true
           
       } catch {
           print("❌ Error in sendAllImages: \(error)")
           self.error = error
           showError(error)
           isLoading = false
           studyViewModel?.isGeneratingQuestions = false
       }
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
    private func generateQuestions(from input: OpenAIService.QuestionInput, parameters: OpenAIService.QuestionParameters) async {
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not initialized")
            return
        }
        
        do {
            let questionTypes: [QuestionType: Int] = [
                .multipleChoice: multipleChoiceCount,
                .fillInBlanks: fillInBlanksCount,
                .trueFalse: trueFalseCount
            ].filter { $0.value > 0 }
            
            // 로깅
            print("🚀 Preparing to send data to OpenAI API:")
            print("• Subject: \(subject.rawValue)")
            print("• Difficulty: \(difficulty.rawValue)")
            print("• Education Level: \(educationLevel.rawValue)")
            print("• Question Types: \(questionTypes)")
            
            let questions = try await openAIService.generateQuestions(
                from: input,
                parameters: parameters
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
            createdAt: Date(),
            educationLevel: self.educationLevel, // 추가
            name: "Default Name" // 추가
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
