// Services/OpenAIService.swift
import Foundation

// Services/OpenAIService.swift
import Foundation

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
    
    func generateQuestions(
        from imageData: Data,
        subject: Subject,
        difficulty: Difficulty,
        questionTypes: [QuestionType: Int]
    ) async throws -> [Question] {
        let base64Image = imageData.base64EncodedString()
        
        // Prepare messages array
        var messages: [[String: Any]] = []
        
        // Add system message
        messages.append([
            "role": "system",
            "content": "You are a tutor creating questions based on images. Generate questions that are clear and appropriate for the given subject and difficulty level."
        ])
        
        // Add user message with image
        messages.append([
            "role": "user",
            "content": [
                [
                    "type": "text",
                    "text": """
                        Generate questions based on the image with the following requirements:
                        Subject: \(subject.rawValue)
                        Difficulty: \(difficulty.rawValue)
                        Question types and counts:
                        \(questionTypes.map { "- \($0.key.rawValue): \($0.value)" }.joined(separator: "\n"))
                        
                        For each question, please provide:
                        1. A clear question text
                        2. Multiple choice options (if applicable)
                        3. The correct answer
                        4. An explanation
                        5. A hint (optional)
                        
                        Format the response as a valid JSON array.
                        """
                ],
                [
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)"
                    ]
                ]
            ]
        ])
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 4000,
            "temperature": 0.7,
            "response_format": ["type": "json_object"]
        ]
        
        // Create request
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            // Make request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // Handle error responses
            guard httpResponse.statusCode == 200 else {
                if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    throw NetworkError.apiError(errorResponse.error.message)
                }
                throw NetworkError.invalidResponse
            }
            
            // Parse response
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return try parseQuestionsFromResponse(decodedResponse, subject: subject, difficulty: difficulty)
            
        } catch {
            throw NetworkError.parsingError(error)
        }
    }
    
    private func parseQuestionsFromResponse(
        _ response: OpenAIResponse,
        subject: Subject,
        difficulty: Difficulty
    ) throws -> [Question] {
        guard let content = response.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
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
                    type: rawQuestion.type ?? .multipleChoice,
                    subject: subject,
                    difficulty: difficulty,
                    question: rawQuestion.question,
                    options: rawQuestion.processedOptions,
                    matchingOptions: rawQuestion.matchingPairs ?? [],
                    correctAnswer: rawQuestion.correctAnswer,
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
}

private struct RawQuestion: Codable {
    let type: QuestionType?
    let question: String
    let options: OptionsType?
    let matchingPairs: [String]?
    let explanation: String
    let hint: String?
    let correct_answer: AnyCodable
    
    // options를 위한 타입 정의
    enum OptionsType: Codable {
        case array([String])
        case dictionary([String: [String]])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let arrayValue = try? container.decode([String].self) {
                self = .array(arrayValue)
            } else if let dictValue = try? container.decode([String: [String]].self) {
                self = .dictionary(dictValue)
            } else {
                throw DecodingError.typeMismatch(
                    OptionsType.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected either array or dictionary of options"
                    )
                )
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type, question, options, explanation, hint
        case correct_answer = "correct_answer"
    }
    
    // Decodable 초기화 구문 추가
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try? container.decode(QuestionType?.self, forKey: .type)
        question = try container.decode(String.self, forKey: .question)
        options = try? container.decode(OptionsType?.self, forKey: .options)
        matchingPairs = try? container.decode([String]?.self, forKey: .options)
        explanation = try container.decode(String.self, forKey: .explanation)
        hint = try? container.decode(String?.self, forKey: .hint)
        correct_answer = try container.decode(AnyCodable.self, forKey: .correct_answer)
    }
    
    var correctAnswer: String {
        switch correct_answer.value {
        case let string as String:
            return string
        case let dict as [String: String]:
            return dict.map { "\($0.key):\($0.value)" }.joined(separator: ",")
        default:
            return String(describing: correct_answer.value)
        }
    }
    
    // options 처리를 위한 계산 속성
    var processedOptions: [String] {
        switch options {
        case .array(let array):
            return array
        case .dictionary(let dict):
            // 딕셔너리 형태의 options를 배열로 변환
            var result: [String] = []
            for (key, values) in dict {
                result.append(key)
                result.append(contentsOf: values)
            }
            return result
        case nil:
            return []
        }
    }
}


struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode([String: String].self) {
            self.value = value
        } else if let value = try? container.decode([String].self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if container.decodeNil() {
            self.value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let value as String:
            try container.encode(value)
        case let value as [String: String]:
            try container.encode(value)
        case let value as [String]:
            try container.encode(value)
        case let value as Bool:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case is NSNull:
            try container.encodeNil()
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable value cannot be encoded"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}

private struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
    
    struct OpenAIError: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}
