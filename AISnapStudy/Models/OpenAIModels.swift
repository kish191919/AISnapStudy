

import Foundation

// MARK: - OpenAI Response Models
struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
}

struct Choice: Codable {
    let message: Message
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct Message: Codable {
    let role: String
    let content: String
    let refusal: String? // 추가: Structured Outputs의 refusal 처리를 위해
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Error Response Models
struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
    
    struct OpenAIError: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}

// MARK: - Question Generation Schema
struct QuestionGenerationSchema: Codable {
    let questions: [QuestionData]
    
    struct QuestionData: Codable {
        let type: String
        let question: String
        let options: [String]
        let correctAnswer: String
        let explanation: String
        let hint: String?
        
        enum CodingKeys: String, CodingKey {
            case type
            case question
            case options
            case correctAnswer
            case explanation
            case hint
        }
    }
}
