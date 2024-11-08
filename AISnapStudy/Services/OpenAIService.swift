
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
                    correctAnswer: rawQuestion.formattedCorrectAnswer,
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

private enum OptionsType: Codable {
    case array([String])
    case dictionary([String: [String]])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([String].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: [String]].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected array or dictionary"
            )
        }
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

private struct RawQuestion: Codable {
    let type: QuestionType?
    let question: String
    let options: OptionsType?
    let matchingPairs: [String]?
    let explanation: String
    let hint: String?
    let pairs: [MatchingPair]?
    let correctAnswer: AnyCodable?
    
    struct MatchingPair: Codable {
        let phrase: String
        let verse: String
    }
    
    enum CodingKeys: String, CodingKey {
        case type, question, options, explanation, hint, pairs
        case correctAnswer = "correctAnswer"
        case matchingPairs
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try? container.decode(QuestionType?.self, forKey: .type)
        question = try container.decode(String.self, forKey: .question)
        options = try? container.decode(OptionsType?.self, forKey: .options)
        pairs = try? container.decode([MatchingPair]?.self, forKey: .pairs)
        explanation = try container.decode(String.self, forKey: .explanation)
        hint = try? container.decode(String?.self, forKey: .hint)
        correctAnswer = try? container.decode(AnyCodable.self, forKey: .correctAnswer)
        matchingPairs = pairs?.map { $0.phrase }
    }
    
    // Encodable 준수를 위한 encode 메서드 추가
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(question, forKey: .question)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encode(explanation, forKey: .explanation)
        try container.encodeIfPresent(hint, forKey: .hint)
        try container.encodeIfPresent(pairs, forKey: .pairs)
        try container.encodeIfPresent(correctAnswer, forKey: .correctAnswer)
        try container.encodeIfPresent(matchingPairs, forKey: .matchingPairs)
    }
    
    // 기존의 계산 속성들은 그대로 유지
    var formattedCorrectAnswer: String {
        if let correctAnswerDict = correctAnswer?.value as? [String: String] {
            return correctAnswerDict.map { "\($0.key):\($0.value)" }.joined(separator: ",")
        } else if let string = correctAnswer?.value as? String {
            return string
        }
        return ""
    }
    
    var processedOptions: [String] {
        if let pairs = pairs {
            return pairs.map { $0.phrase }
        } else if let options = options {
            switch options {
            case .array(let array):
                return array
            case .dictionary(let dict):
                var result: [String] = []
                for (key, values) in dict {
                    result.append(key)
                    result.append(contentsOf: values)
                }
                return result
            }
        }
        return []
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

