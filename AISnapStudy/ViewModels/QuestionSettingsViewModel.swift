
// ViewModels/QuestionSettingsViewModel.swift
import Foundation
import SwiftUI
import PhotosUI

class QuestionSettingsViewModel: ObservableObject {
    private let homeViewModel: HomeViewModel

    @Published var difficulty: Difficulty = .medium
    @Published var multipleChoiceCount = 0
    @Published var fillInBlanksCount = 0
    @Published var matchingCount = 0
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var selectedImage: UIImage? {
        didSet {
            if let image = selectedImage {
                Task {
                    await processImage(image)
                }
            }
        }
    }
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    private var openAIService: OpenAIService?
    private let imageService = ImageService.shared
    let subject: Subject

    init(subject: Subject, homeViewModel: HomeViewModel) {
        self.subject = subject
        self.homeViewModel = homeViewModel
        setupInitialState()
    }

    private func setupInitialState() {
        // Initialize OpenAI service
        DispatchQueue.main.async { [weak self] in
            do {
                self?.openAIService = try OpenAIService()
            } catch {
                self?.error = error
                print("Failed to initialize OpenAI service:", error)
            }
        }

        // Reset all counters
        multipleChoiceCount = 0
        fillInBlanksCount = 0
        matchingCount = 0

        // Reset other states
        isLoading = false
        showImagePicker = false
        showCamera = false
        selectedImage = nil
        error = nil

        // Use homeViewModel
        homeViewModel.loadData()
        homeViewModel.selectedProblemSet = nil
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

    @MainActor
    func processImage(_ image: UIImage) async {
        isLoading = true
        do {
            // Log original image size
            print("Original image size:", image.size)

            let compressedData = try await Task {
                try ImageCompressor.shared.compressForAPI(image)
            }.value

            // Log compressed image data size
            print("Compressed image data size:", compressedData.count)

            // Validate image data
            guard compressedData.count > 0 else {
                throw ImageCompressorError.compressionFailed
            }

            // Validate OpenAI service
            guard let openAIService = self.openAIService else {
                throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI service not initialized"])
            }

            await generateQuestions(from: compressedData, subject: .math)
        } catch {
            await MainActor.run {
                self.error = error
                self.showError(error)
                print("Image processing error:", error)
            }
        }
        await MainActor.run {
            self.isLoading = false
        }
    }

    @MainActor
    func generateQuestions(from imageData: Data, subject: Subject) async {
        guard let openAIService = openAIService else { return }

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
            processGeneratedQuestions(questions)

        } catch {
            self.error = error
            isLoading = false
            showError(error)
            print("Question generation error:", error)
        }
    }

    @MainActor
    private func processGeneratedQuestions(_ questions: [Question]) {
        do {
            let problemSet = ProblemSet(
                id: UUID().uuidString,
                title: "Generated Questions",
                subject: questions.first?.subject ?? .math,
                difficulty: difficulty,
                questions: questions,
                createdAt: Date()
            )

            try StorageService().saveProblemSet(problemSet)

            homeViewModel.loadData()
            homeViewModel.selectedProblemSet = problemSet

            showSuccess()

        } catch {
            self.error = error
            showError(error)
            print("Problem set saving error:", error)
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
