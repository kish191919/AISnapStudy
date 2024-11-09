// Models/NetworkError.swift
import Foundation

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case connectionLost
    case invalidResponse
    case invalidData
    case apiError(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available. Please check your connection and try again."
        case .timeout:
            return "The request timed out. Please try again."
        case .connectionLost:
            return "The network connection was lost. Please try again."
        case .invalidResponse:
            return "Invalid response received from the server."
        case .invalidData:
            return "Invalid data received from the server."
        case .apiError(let message):
            return "API Error: \(message)"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
