// Utils/Helpers/ErrorHandler.swift
import Foundation

enum AppError: Error {
    case networkError(String)
    case imageProcessingError(String)
    case storageError(String)
    case openAIError(String)
}

class ErrorHandler {
    static func handle(_ error: Error) {
        // 실제 구현에서는 에러 로깅, 사용자 알림 등을 처리
        print("Error occurred: \(error.localizedDescription)")
    }
}
