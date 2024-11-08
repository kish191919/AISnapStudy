
// Services/OpenAIService.swift
import Foundation

// MARK: - OpenAI Response Models
struct AIResponse: Codable {
   let id: String
   let object: String
   let created: Int
   let model: String
   let choices: [AIChoice]
   let usage: AIUsage
}

struct AIChoice: Codable {
   let message: AIMessage
   let finishReason: String?
   
   enum CodingKeys: String, CodingKey {
       case message
       case finishReason = "finish_reason"
   }
}

struct AIMessage: Codable {
   let role: String
   let content: String
}

struct AIUsage: Codable {
   let promptTokens: Int
   let completionTokens: Int
   let totalTokens: Int
   
   enum CodingKeys: String, CodingKey {
       case promptTokens = "prompt_tokens"
       case completionTokens = "completion_tokens"
       case totalTokens = "total_tokens"
   }
}

// MARK: - OpenAI Service
class OpenAIService {
   private let apiKey: String
   private let baseURL = "https://api.openai.com/v1/chat/completions"
   
   init() throws {
       // Load API key from Configuration.plist
       do {
           self.apiKey = try ConfigurationManager.shared.getValue(for: "OpenAIAPIKey")
       } catch {
           print("Failed to load OpenAI API key: \(error)")
           throw error
       }
   }
   
   // MARK: - API Response Logging
   private func logAPIResponse(_ data: Data) {
       if let jsonString = String(data: data, encoding: .utf8) {
           print("📥 OpenAI API Response:")
           print(jsonString)
       }
   }
   
   // MARK: - Question Generation
   func generateQuestions(
       from imageData: Data,
       subject: Subject,
       difficulty: Difficulty,
       questionTypes: [QuestionType: Int]
   ) async throws -> [Question] {
       let base64Image = imageData.base64EncodedString()
       
       // System prompt
       let systemPrompt = """
       You are an expert tutor creating educational questions based on images. 
       Generate questions that are clear, engaging, and appropriate for the given subject and difficulty level.
       For each question, provide:
       - A clear question text in the "question" field
       - Multiple choice options in the "options" field (for multiple choice questions)
       - The correct answer in the "correctAnswer" field
       - A detailed explanation in the "explanation" field
       - A helpful hint in the "hint" field (optional)
       Format the response as a valid JSON object with a "questions" array.
       """
       
       // User prompt
       let userPrompt = """
       Generate questions based on the image with the following requirements:
       Subject: \(subject.rawValue)
       Difficulty: \(difficulty.rawValue)
       Question types and counts:
       \(questionTypes.map { "- \($0.key.rawValue): \($0.value)" }.joined(separator: "\n"))
       
       Ensure each question follows this JSON structure:
       {
         "questions": [
           {
             "type": "multiple_choice",
             "question": "What is shown in the image?",
             "options": ["A", "B", "C", "D"],
             "correctAnswer": "A",
             "explanation": "Detailed explanation here",
             "hint": "Optional hint here"
           }
         ]
       }
       """
       
       let messages: [[String: Any]] = [
           ["role": "system", "content": systemPrompt],
           ["role": "user", "content": [
               ["type": "text", "text": userPrompt],
               ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
           ]]
       ]
       
       let requestBody: [String: Any] = [
           "model": "gpt-4o",
           "messages": messages,
           "max_tokens": 4000,
           "temperature": 0.7,
           "response_format": ["type": "json_object"]
       ]
       
       var request = URLRequest(url: URL(string: baseURL)!)
       request.httpMethod = "POST"
       request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
       request.setValue("application/json", forHTTPHeaderField: "Content-Type")
       request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
       
       let (data, response) = try await URLSession.shared.data(for: request)
       
       // 응답 로깅
       logAPIResponse(data)
       
       guard let httpResponse = response as? HTTPURLResponse else {
           throw NetworkError.invalidResponse
       }
       
       guard httpResponse.statusCode == 200 else {
           if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
               throw NetworkError.apiError(errorResponse.error.message)
           }
           throw NetworkError.invalidResponse
       }
       
       let decodedResponse = try JSONDecoder().decode(AIResponse.self, from: data)
       return try parseQuestionsFromResponse(decodedResponse, subject: subject, difficulty: difficulty)
   }
   
   // MARK: - Response Parsing
    // MARK: - Response Parsing
    private func parseQuestionsFromResponse(
        _ response: AIResponse,
        subject: Subject,
        difficulty: Difficulty
    ) throws -> [Question] {
        guard let content = response.choices.first?.message.content,
              let jsonData = content.data(using: String.Encoding.utf8) else {
            throw NetworkError.invalidData
        }
        
        print("Received JSON content:", content)
        
        do {
            let decoder = JSONDecoder()
            struct APIResponse: Codable {
                let questions: [RawQuestion]
            }
            
            let apiResponse = try decoder.decode(APIResponse.self, from: jsonData)
            
            return apiResponse.questions.map { rawQuestion in
                Question(
                    id: UUID().uuidString,
                    type: rawQuestion.questionType,
                    subject: subject,
                    difficulty: difficulty,
                    question: rawQuestion.question,
                    options: rawQuestion.processedOptions,
                    matchingOptions: rawQuestion.matchingPairs,
                    correctAnswer: rawQuestion.processedCorrectAnswer,
                    explanation: rawQuestion.explanation,
                    hint: rawQuestion.hint,
                    isSaved: false,
                    createdAt: Date()
                )
            }
        } catch {
            print("JSON Parsing error:", error)
            throw NetworkError.parsingError(error)
        }
    }
    
// MARK: - Question Models
    // MARK: - Question Models
    private struct RawQuestion: Codable {
        let type: String?
        let question: String
        let options: OptionType?  // optional로 변경
        let correctAnswer: AnswerType
        let explanation: String
        let hint: String?
        
        // MARK: - Option Type
        enum OptionType: Codable {
            case array([String])
            case dictionary([String: String])
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                
                // First try array
                if let arrayValue = try? container.decode([String].self) {
                    self = .array(arrayValue)
                    return
                }
                
                // Then try dictionary
                if let dictValue = try? container.decode([String: String].self) {
                    self = .dictionary(dictValue)
                    return
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Options must be either an array of strings or a dictionary"
                )
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .array(let array):
                    try container.encode(array)
                case .dictionary(let dict):
                    try container.encode(dict)
                }
            }
        }
        
        // MARK: - Answer Type
        enum AnswerType: Codable {
            case single(String)
            case multiple([String: String])
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                
                // First try single string
                if let stringValue = try? container.decode(String.self) {
                    self = .single(stringValue)
                    return
                }
                
                // Then try dictionary
                if let dictValue = try? container.decode([String: String].self) {
                    self = .multiple(dictValue)
                    return
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Answer must be either a string or a dictionary"
                )
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .single(let string):
                    try container.encode(string)
                case .multiple(let dict):
                    try container.encode(dict)
                }
            }
        }
        
        // MARK: - Computed Properties
        var questionType: QuestionType {
            QuestionType(rawValue: type ?? "") ?? .multipleChoice
        }
        
        var processedOptions: [String] {
            guard let options = options else { return [] }
            
            switch options {
            case .array(let array):
                return array
            case .dictionary(let dict):
                return dict.map { "\($0): \($1)" }
            }
        }
        
        var processedCorrectAnswer: String {
            switch correctAnswer {
            case .single(let answer):
                return answer
            case .multiple(let dict):
                return dict.map { "\($0):\($1)" }.joined(separator: ",")
            }
        }
        
        var matchingPairs: [String] {
            if case .dictionary(let dict) = options {
                return Array(dict.keys)
            }
            return []
        }
        
        // MARK: - CodingKeys
        private enum CodingKeys: String, CodingKey {
            case type, question, options, correctAnswer, explanation, hint
        }
        
        // Custom decoding
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            type = try container.decodeIfPresent(String.self, forKey: .type)
            question = try container.decode(String.self, forKey: .question)
            options = try container.decodeIfPresent(OptionType.self, forKey: .options)
            correctAnswer = try container.decode(AnswerType.self, forKey: .correctAnswer)
            explanation = try container.decode(String.self, forKey: .explanation)
            hint = try container.decodeIfPresent(String.self, forKey: .hint)
        }
    }

// MARK: - Error Models
private struct OpenAIErrorResponse: Codable {
   let error: OpenAIError
   
   struct OpenAIError: Codable {
       let message: String
       let type: String?
       let code: String?
   }
}

    // MARK: - Error Types
    enum NetworkError: Error {
        case invalidResponse
        case invalidData
        case apiError(String)
        case parsingError(Error)
        
        var localizedDescription: String {
            switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .invalidData:
                return "Invalid data received"
            case .apiError(let message):
                return "API Error: \(message)"
            case .parsingError(let error):
                return "Parsing error: \(error.localizedDescription)"
            }
        }
    }

}
