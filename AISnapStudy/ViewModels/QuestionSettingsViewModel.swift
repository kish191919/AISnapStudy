
import Foundation
import SwiftUI
import PhotosUI

class QuestionSettingsViewModel: ObservableObject {
    private let homeViewModel: HomeViewModel
    private let networkMonitor = NetworkMonitor.shared
    private var openAIService: OpenAIService?
    private let imageService = ImageService.shared
    let subject: Subject
    
    // MARK: - Published Properties
    @Published var difficulty: Difficulty = .medium
    @Published var multipleChoiceCount: Int = 0 {
        didSet {
            print("ViewModel - Multiple Choice Count updated to: \(multipleChoiceCount)")
        }
    }
    @Published var fillInBlanksCount: Int = 0 {
        didSet {
            print("ViewModel - Fill in Blanks Count updated to: \(fillInBlanksCount)")
        }
    }
    @Published var matchingCount: Int = 0 {
        didSet {
            print("ViewModel - Matching Count updated to: \(matchingCount)")
        }
    }
    
    @Published var isLoading = false
    @Published var error: Error?
    @Published var networkError: NetworkError?
    @Published var isNetworkAvailable = true
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var selectedImages: [UIImage] = []
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var selectedImage: UIImage? {
        didSet {
            if let image = selectedImage {
                Task { @MainActor in
                    await addImage(image)
                    selectedImage = nil
                }
            }
        }
    }
    
    // MARK: - Initialization
    init(subject: Subject, homeViewModel: HomeViewModel) {
        self.subject = subject
        self.homeViewModel = homeViewModel
        
        // 네트워크 상태 옵저빙
        setupNetworkMonitoring()
        
        // OpenAI 서비스 초기화
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
    }
    
    var hasValidQuestionCount: Bool {
        multipleChoiceCount + fillInBlanksCount + matchingCount > 0
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
                print("Image added. Total images: \(selectedImages.count)")
            }
        } catch {
            self.error = error
            showError(error)
        }
    }
    
    func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    @MainActor
    func sendAllImages() async {
        guard !selectedImages.isEmpty else { return }
        
        // 네트워크 연결 확인
        guard networkMonitor.isReachable else {
            showError(NetworkError.noConnection as Error)
            return
        }
        
        isLoading = true
        
        do {
            for image in selectedImages {
                let compressedData = try await Task {
                    try ImageCompressor.shared.compressForAPI(image)
                }.value
                
                await generateQuestions(from: compressedData, subject: subject)
            }
            
            selectedImages.removeAll()
            showSuccess()
        } catch {
            self.error = error
            showError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Image Capture Methods
    @MainActor
    func takePhoto() {
        Task {
            do {
                let hasPermission = try await imageService.requestPermission(for: .camera)
                if hasPermission {
                    showCamera = true
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
    }
    
    @MainActor
    func selectFromGallery() {
        Task {
            do {
                let hasPermission = try await imageService.requestPermission(for: .gallery)
                if hasPermission {
                    showImagePicker = true
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
    }
    
    // MARK: - Question Generation
    @MainActor
    private func generateQuestions(from imageData: Data, subject: Subject) async {
        guard let openAIService = openAIService else {
            print("OpenAI service not initialized")
            return
        }
        
        isLoading = true
        
        do {
            let questionTypes: [QuestionType: Int] = [
                .multipleChoice: multipleChoiceCount,
                .fillInBlanks: fillInBlanksCount,
                .matching: matchingCount
            ]
            
            let questions = try await openAIService.generateQuestions(
                from: imageData,
                subject: subject,
                difficulty: difficulty,
                questionTypes: questionTypes
            )
            
            isLoading = false
            await processGeneratedQuestions(questions)
        } catch {
            self.error = error
            isLoading = false
            showError(error)
            print("Question generation error:", error)
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
