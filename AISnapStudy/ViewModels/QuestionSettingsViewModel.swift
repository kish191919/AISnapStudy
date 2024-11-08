
// ViewModels/QuestionSettingsViewModel.swift
import Foundation
import SwiftUI
import PhotosUI

class QuestionSettingsViewModel: ObservableObject {
    private let homeViewModel: HomeViewModel

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
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var selectedImages: [UIImage] = []  // 추가: 이미지 배열
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    // selectedImage didSet 추가
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
    private var openAIService: OpenAIService?
    private let imageService = ImageService.shared
    let subject: Subject

    init(subject: Subject, homeViewModel: HomeViewModel) {
        self.subject = subject
        self.homeViewModel = homeViewModel
        
        // OpenAI 서비스 초기화
        do {
            self.openAIService = try OpenAIService()
        } catch {
            self.error = error
            print("Failed to initialize OpenAI service:", error)
        }
    }

    // 추가: 이미지를 배열에 추가하는 메서드
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

    // 추가: 이미지를 배열에서 제거하는 메서드
    func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }

    // 추가: 모든 이미지를 OpenAI로 전송하는 메서드
    @MainActor
    func sendAllImages() async {
        guard !selectedImages.isEmpty else { return }
        
        isLoading = true
        var processedCount = 0
        
        do {
            for image in selectedImages {
                let compressedData = try await Task {
                    try ImageCompressor.shared.compressForAPI(image)
                }.value
                
                await generateQuestions(from: compressedData, subject: subject)
                processedCount += 1
            }
            
            // 모든 처리가 완료되면 이미지 배열 비우기
            selectedImages.removeAll()
            showSuccess()
        } catch {
            self.error = error
            showError(error)
        }
        
        isLoading = false
    }

    // loadData 메서드도 async로 수정
    func loadData() async {
        await homeViewModel.loadData()
    }

    func resetCounts() {
        multipleChoiceCount = 0
        fillInBlanksCount = 0
        matchingCount = 0
    }

    func updateSelectedProblemSet(_ problemSet: ProblemSet?) {
        homeViewModel.setSelectedProblemSet(problemSet)
    }

    private func clearSelectedProblemSet() {
        homeViewModel.clearSelectedProblemSet()
    }

    var hasValidQuestionCount: Bool {
        multipleChoiceCount + fillInBlanksCount + matchingCount > 0
    }

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

    // selectedImage didSet 처리를 별도 메서드로 수정
    @MainActor
        func processSelectedImage() async {
            if let image = selectedImage {
                await addImage(image)
                selectedImage = nil
            }
        }

    @MainActor
    private func processGeneratedQuestions(_ questions: [Question]) async {
        do {
            print("🔵 Processing generated questions:")
            print("Number of questions: \(questions.count)")
            print("Questions details: \(questions.map { "[\($0.type): \($0.question)]" }.joined(separator: "\n"))")
            
            let subject = questions.first?.subject ?? self.subject
            let problemSet = ProblemSet(
                id: UUID().uuidString,
                title: "Generated Questions",
                subject: subject,
                difficulty: difficulty,
                questions: questions,
                createdAt: Date()
            )
            
            print("🔵 Created ProblemSet:")
            print("ID: \(problemSet.id)")
            print("Subject: \(problemSet.subject)")
            print("Question count: \(problemSet.questionCount)")

            // CoreData를 사용하여 저장
            try await Task.detached {
                try CoreDataService.shared.saveProblemSet(problemSet)
            }.value
            print("✅ Successfully saved ProblemSet to CoreData")

            // 데이터 다시 로드
            await homeViewModel.loadData()
            print("✅ Called homeViewModel.loadData()")
            
            homeViewModel.setSelectedProblemSet(problemSet)
            print("✅ Set selected ProblemSet in homeViewModel")
            print("Selected ProblemSet ID: \(problemSet.id)")

            showSuccess()
        } catch {
            self.error = error
            print("❌ Error in processGeneratedQuestions: \(error)")
            showError(error)
        }
    }

    // generateQuestions 메서드도 수정 필요
    @MainActor
    func generateQuestions(from imageData: Data, subject: Subject) async {
        if let openAIService = openAIService {
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
        } else {
            print("OpenAI service not initialized")
        }
    }

   @MainActor
   private func showError(_ error: Error) {
       print("Error details:", error.localizedDescription)

       if let imageError = error as? ImageServiceError {
           switch imageError {
           case .permissionDenied:
               alertTitle = "Permission Error"
               alertMessage = "Camera or photo library access is not authorized. Please enable access in Settings."
           case .unavailable:
               alertTitle = "Unavailable"
               alertMessage = "This feature is not available on your device."
           case .compressionFailed:
               alertTitle = "Compression Error"
               alertMessage = "Failed to compress the image. Please try another image."
           case .unknown(let underlyingError):
               alertTitle = "Error"
               alertMessage = underlyingError.localizedDescription
           }
       } else if let networkError = error as? NetworkError {
           alertTitle = "Network Error"
           alertMessage = networkError.localizedDescription
       } else {
           alertTitle = "Error"
           alertMessage = "An error occurred while processing the image. Please try again. (\(error.localizedDescription))"
       }
       showAlert = true
   }

   @MainActor
   func showSuccess() {
       alertTitle = "Success"
       alertMessage = "Questions have been successfully generated."
       showAlert = true
   }
}
