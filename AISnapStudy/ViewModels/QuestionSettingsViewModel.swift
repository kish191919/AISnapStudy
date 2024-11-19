
import Foundation
import SwiftUI
import PhotosUI

@MainActor
class QuestionSettingsViewModel: ObservableObject {
    // Quick Text Mode 상태가 @Published로 선언되어 있는지 확인
    @Published var useTextExtraction: Bool = true {
        didSet {
            UserDefaults.standard.set(useTextExtraction, forKey: "useTextExtraction")
        }
    }
    
    @Published var selectedLanguage: Language = .auto {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    // TextExtraction 관련 상태들
    @Published var extractedTexts: [String: String] = [:]
    @Published var isLoadingTexts: [String: Bool] = [:]
    @Published var extractionStatus: [String: Bool] = [:]
    @Published private(set) var isCameraAuthorized = false
    @Published private(set) var isGalleryAuthorized = false
    
    private let homeViewModel: HomeViewModel
    private let networkMonitor = NetworkMonitor.shared
    private let imageService = ImageService.shared
    private var openAIService: OpenAIService?
    private let totalMaximumQuestions = 10
    private var studyViewModel: StudyViewModel?
    
    // MARK: - UserDefaults keys
    private enum UserDefaultsKeys {
        static let lastSubject = "lastSelectedSubject"
        static let lastEducationLevel = "lastEducationLevel"
        static let lastMultipleChoiceCount = "lastMultipleChoiceCount"
        static let lastTrueFalseCount = "lastTrueFalseCount"
    }
    
    // MARK: - Published Properties

    private var imageIds: [UIImage: String] = [:]
    
    @Published var selectedImages: [UIImage] = []
    @Published var hasCameraImage: Bool = false
    @Published var hasGalleryImages: Bool = false
    @Published var questionText: String = ""
    @Published var isUsingTextInput: Bool = false
    @Published var isTextInputActive: Bool = false
    @Published var hasSelectedCamera: Bool = false
    @Published var hasSelectedGallery: Bool = false
    @Published var shouldCollapseQuestionTypes = false
    @Published var shouldShowStudyView: Bool = false
    @Published var isGeneratingQuestions: Bool = false
    @Published var problemSetName: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var networkError: NetworkError?
    @Published var isNetworkAvailable: Bool = true
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var selectedImage: UIImage?
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    @Published var selectedSubject: Subject {
         didSet {
             UserDefaults.standard.set(selectedSubject.rawValue, forKey: UserDefaultsKeys.lastSubject)
         }
     }
     
     @Published var educationLevel: EducationLevel {
         didSet {
             UserDefaults.standard.set(educationLevel.rawValue, forKey: UserDefaultsKeys.lastEducationLevel)
         }
     }
     
     @Published var multipleChoiceCount: Int {
         didSet {
             UserDefaults.standard.set(multipleChoiceCount, forKey: UserDefaultsKeys.lastMultipleChoiceCount)
         }
     }
     
     @Published var trueFalseCount: Int {
         didSet {
             UserDefaults.standard.set(trueFalseCount, forKey: UserDefaultsKeys.lastTrueFalseCount)
         }
     }
     
     let subject: Subject
    
     
     // MARK: - Initialization
     init(subject: Subject, homeViewModel: HomeViewModel) {
         
         self.subject = subject
         self.homeViewModel = homeViewModel
         self.studyViewModel = homeViewModel.studyViewModel
         
         // UserDefaults에서 마지막 설정값을 불러오거나, 선택된 subject 사용
         let lastSubjectRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastSubject)
         let lastEducationLevelRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastEducationLevel)

         
         // 기본값을 하드코딩하지 않고 파라미터나 null 처리
         self.selectedSubject = Subject(rawValue: lastSubjectRaw ?? "") ?? subject
         self.educationLevel = EducationLevel(rawValue: lastEducationLevelRaw ?? "") ?? .elementary
         self.multipleChoiceCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.lastMultipleChoiceCount)
         self.trueFalseCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.lastTrueFalseCount)
         
         // Initialize network monitoring
         self.isNetworkAvailable = networkMonitor.isReachable
         
         // 기본값 설정
         UserDefaults.standard.register(defaults: ["useTextExtraction": true])
         // 저장된 값 로드
         self.useTextExtraction = UserDefaults.standard.bool(forKey: "useTextExtraction")
         print("📱 Initial useTextExtraction value loaded: \(useTextExtraction)")
         
         // 저장된 언어 설정 불러오기
         if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
            let language = Language(rawValue: savedLanguage) {
             self.selectedLanguage = language
         }
         
         
         // Initialize OpenAI service
         do {
             self.openAIService = try OpenAIService()
         } catch {
             self.error = error
             print("Failed to initialize OpenAI service:", error)
         }
     }
    
    // Add permission check methods
    func checkCameraPermission() async -> Bool {
        do {
            return try await imageService.requestPermission(for: .camera)
        } catch {
            await MainActor.run {
                showError(error)
            }
            return false
        }
    }
    
    func checkGalleryPermission() async -> Bool {
        do {
            return try await imageService.requestPermission(for: .gallery)
        } catch {
            await MainActor.run {
                showError(error)
            }
            return false
        }
    }
     
     // MARK: - Image Management
     private func generateImageId() -> String {
         return UUID().uuidString
     }
     
    func getImageId(for image: UIImage) -> String {
        if let existingId = imageIds[image] {
            return existingId
        }
        let newId = generateImageId()
        imageIds[image] = newId
        return newId
    }

    // 새로운 함수 추가
    private func sendExtractedTextToOpenAI(_ text: String) async throws {
        print("📤 Preparing to send extracted text to OpenAI")
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not initialized")
            return
        }
        
        do {
            let response = try await openAIService.sendTextExtractionResult(text)
            print("✅ OpenAI processing completed for extracted text")
            print("📥 OpenAI Response: \(response)")
        } catch {
            print("❌ Failed to process extracted text with OpenAI: \(error)")
            throw error
        }
    }

    private func sendImageToOpenAI(_ imageData: Data) async throws {
        print("📤 Preparing to send image to OpenAI")
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not initialized")
            return
        }
        
        do {
            try await openAIService.sendImageDataToOpenAI(imageData)
            print("✅ Image successfully sent to OpenAI")
        } catch {
            print("❌ Failed to send image to OpenAI: \(error)")
            throw error
        }
    }

    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        
        let imageToRemove = selectedImages[index]
        if let imageId = imageIds[imageToRemove] {
            // Remove extracted text for this image
            extractedTexts.removeValue(forKey: imageId)
            imageIds.removeValue(forKey: imageToRemove)
            print("🗑️ Removed text for image: \(imageId)")
        }
        
        selectedImages.remove(at: index)
        
        if selectedImages.isEmpty {
            hasCameraImage = false
            hasGalleryImages = false
            isUsingTextInput = false
            hasSelectedCamera = false
            hasSelectedGallery = false
        }
    }
    
    
    func saveProblemSetName() {
        if problemSetName.isEmpty {
            problemSetName = generateDefaultName()
        }
        
        // 이름이 저장되었음을 알리는 피드백 제공
        HapticManager.shared.impact(style: .medium)
        print("Problem Set name saved: \(problemSetName)")
        
        // 질문 생성이 완료되었고 이름이 저장되었을 때만 StudyView로 이동
        if !isGeneratingQuestions {
            shouldShowStudyView = true
        }
    }
    
    // 기본 이름 생성 메서드
    func generateDefaultName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMdd_HHmm"
        let dateString = dateFormatter.string(from: Date())
        let totalQuestions = multipleChoiceCount + trueFalseCount
        
        return "\(selectedSubject.displayName)_\(totalQuestions)Q_\(dateString)"
        // 예: "Math_10Q_0515_1430"
    }
     
     // 기존 resetCounts 메서드 수정
     func resetCounts() {
         // Reset counts without clearing UserDefaults
         multipleChoiceCount = 0
         trueFalseCount = 0
         hasCameraImage = false
         hasGalleryImages = false
     }
     
     // UserDefaults 완전 초기화가 필요한 경우를 위한 새로운 메서드
     func resetAllSettings() {
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastSubject)
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastEducationLevel)
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastMultipleChoiceCount)
         UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastTrueFalseCount)
         
         // Reset to defaults
         selectedSubject = subject
         educationLevel = .elementary
         resetCounts()
     }
    
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
        multipleChoiceCount + trueFalseCount
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
        multipleChoiceCount + trueFalseCount > 0
    }
    
    @MainActor
    func loadData() async {
        await homeViewModel.loadData()
    }

    @MainActor
    func addImage(_ image: UIImage) async {
       print("📸 Starting addImage processing...")
       do {
           let compressedData = try await Task {
               try ImageService.shared.compressForAPI(image)
           }.value

           if let compressedImage = UIImage(data: compressedData) {
               selectedImages.append(compressedImage)
               let imageId = getImageId(for: compressedImage)

               if useTextExtraction {
                   print("🔍 Text extraction enabled for image: \(imageId)")
                   isLoadingTexts[imageId] = true
                   
                   // FileProvider 에러와 상관없이 Vision API 사용
                   do {
                       // VisionService를 통한 텍스트 추출
                       print("📝 Starting Vision API text extraction...")
                       let extractedText = try await VisionService.shared.extractText(from: compressedImage)
                       
                       if !extractedText.isEmpty {
                           print("✅ Text extracted successfully: \(extractedText)")
                           await MainActor.run {
                               extractedTexts[imageId] = extractedText
                               extractionStatus[imageId] = true
                               isLoadingTexts[imageId] = false
                           }
                       } else {
                           print("⚠️ No text extracted from image")
                           await MainActor.run {
                               extractionStatus[imageId] = false
                               isLoadingTexts[imageId] = false
                           }
                       }
                   } catch {
                       print("❌ Text extraction failed: \(error.localizedDescription)")
                       await MainActor.run {
                           extractionStatus[imageId] = false
                           isLoadingTexts[imageId] = false
                       }
                   }
               } else {
                   print("ℹ️ Text extraction disabled - using image directly")
               }
           }
       } catch {
           print("❌ Error in image processing: \(error.localizedDescription)")
           self.error = error
           showError(error)
       }
    }
    
    
    @MainActor
    func sendAllImages() async {
       print("🚀 Starting sendAllImages process...")
       guard !selectedImages.isEmpty || !questionText.isEmpty else {
           print("❌ No content to generate questions from")
           return
       }
       
       isLoading = true
       studyViewModel?.isGeneratingQuestions = true
       
       do {
           var allExtractedText = ""
           var imagesForDirectProcessing: [UIImage] = []
           
           // 이미지 처리
           for image in selectedImages {
               let imageId = getImageId(for: image)
               print("📸 Processing image: \(imageId)")
               
               if useTextExtraction {
                   print("🔍 Text extraction enabled - attempting to extract text...")
                   do {
                       let extractedText = try await VisionService.shared.extractText(from: image)
                       if !extractedText.isEmpty {
                           print("✅ Successfully extracted text: \(extractedText)")
                           allExtractedText += extractedText + "\n"
                       } else {
                           print("⚠️ No text extracted, adding to direct processing queue")
                           imagesForDirectProcessing.append(image)
                       }
                   } catch {
                       print("❌ Error extracting text from image: \(error)")
                       imagesForDirectProcessing.append(image)
                   }
               } else {
                   print("ℹ️ Text extraction disabled - adding to direct processing queue")
                   imagesForDirectProcessing.append(image)
               }
           }

           // 텍스트 입력 처리
           if !questionText.isEmpty {
               let textInput = OpenAIService.QuestionInput(
                   content: questionText.data(using: .utf8) ?? Data(),
                   isImage: false
               )
               print("📝 Processing text input")
               await generateQuestions(from: textInput, parameters: createParameters())
           }
           
           // 추출된 텍스트 처리
           if !allExtractedText.isEmpty {
               let input = OpenAIService.QuestionInput(
                   content: allExtractedText.data(using: .utf8) ?? Data(),
                   isImage: false
               )
               print("📤 Sending extracted text to OpenAI")
               await generateQuestions(from: input, parameters: createParameters())
           }
           
           // 직접 이미지 처리가 필요한 경우 처리
           if !imagesForDirectProcessing.isEmpty {
               print("📸 Processing \(imagesForDirectProcessing.count) images directly")
               for image in imagesForDirectProcessing {
                   print("🖼️ Direct processing image")
                   try await processImageDirectly(image)
               }
           }
           
           isLoading = false
           studyViewModel?.isGeneratingQuestions = false
           showSuccess()
           shouldShowStudyView = true
           
       } catch {
           print("❌ Error in sendAllImages: \(error.localizedDescription)")
           isLoading = false
           studyViewModel?.isGeneratingQuestions = false
           self.error = error
           showError(error)
       }
    }
    // generateQuestions(from:parameters:) 보조 함수
    private func generateQuestions(from input: OpenAIService.QuestionInput, parameters: OpenAIService.QuestionParameters) async {
       print("🔄 Starting question generation from input")
       guard let openAIService = self.openAIService else {
           print("❌ OpenAI service not initialized")
           return
       }
       
       do {
           let questions = try await openAIService.generateQuestions(from: input, parameters: parameters)
           print("✅ Successfully generated \(questions.count) questions")
           
           let name = problemSetName.isEmpty ? generateDefaultName() : problemSetName
           await processGeneratedQuestions(questions, name: name)
       } catch {
           print("❌ Error generating questions: \(error)")
           await MainActor.run {
               self.error = error
               showError(error)
           }
       }
    }

    // 직접 이미지 처리를 위한 함수도 수정
    private func processImageDirectly(_ image: UIImage) async throws {
        print("🖼️ Processing image directly...")
        guard let openAIService = self.openAIService else {
            throw NetworkError.apiError("OpenAI service not initialized")
        }
        
        let compressedData = try await imageService.compressForAPI(image)
        let input = OpenAIService.QuestionInput(
            content: compressedData,
            isImage: true
        )
        print("📤 Sending image to OpenAI")
        let questions = try await openAIService.generateQuestions(from: input, parameters: createParameters())
        await processGeneratedQuestions(questions, name: problemSetName)
    }

    private func createParameters() -> OpenAIService.QuestionParameters {
        return OpenAIService.QuestionParameters(
            subject: selectedSubject,
            educationLevel: educationLevel,
            questionTypes: [
                .multipleChoice: multipleChoiceCount,
                .trueFalse: trueFalseCount
            ],
            language: selectedLanguage  // language 파라미터 추가
        )
    }
    // Update image handling methods
    @MainActor
    func handleCameraImage(_ image: UIImage?) {
        print("📸 Processing camera image...")
        guard let image = image else {
            print("❌ No image captured")
            return
        }

        Task {
            do {
                let orientedImage = image.fixedOrientation()
                await addImage(orientedImage)
                hasCameraImage = true
                hasSelectedCamera = true
                hasSelectedGallery = false
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
                hasSelectedCamera = false  // Reset camera selection
                hasSelectedGallery = true
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

    @MainActor
    func takePhoto() async {
        print("📸 Taking photo...")
        do {
            let hasPermission = try await imageService.requestPermission(for: .camera)
            if hasPermission {
                hasSelectedGallery = false  // Reset gallery selection
                hasSelectedCamera = true
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
    func processGeneratedQuestions(_ questions: [Question], name: String) async {
        print("\n🔄 Processing Generated Questions:")
        print("Number of questions by type:")
        let questionsByType = Dictionary(grouping: questions, by: { $0.type })
        questionsByType.forEach { type, questions in
            print("- \(type.rawValue): \(questions.count) questions")
        }
        
        let subject = questions.first?.subject ?? self.subject
        let problemSet = ProblemSet(
            id: UUID().uuidString,
            subject: subject,
            questions: questions,
            createdAt: Date(),
            educationLevel: self.educationLevel,
            name: name  // 전달받은 이름 사용
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
