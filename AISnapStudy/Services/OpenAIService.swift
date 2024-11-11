
import AISnapStudy // NetworkError import
import Foundation

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    
    init() throws {
        self.apiKey = try ConfigurationManager.shared.getValue(for: "OpenAIAPIKey")
        
        // URLSession 설정
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        
        self.session = URLSession(configuration: configuration)
    }
    
    func generateQuestions(
        from imageData: Data,
        subject: Subject,
        difficulty: Difficulty,
        questionTypes: [QuestionType: Int]
    ) async throws -> [Question] {
        // 네트워크 연결 확인
        guard NetworkMonitor.shared.isReachable else {
            throw NetworkError.noConnection
        }
        
        print("🚀 Generating questions:")
        print("• Subject: \(subject.rawValue)")
        print("• Difficulty: \(difficulty.rawValue)")
        print("• Question Types: \(questionTypes)")
        
        let base64Image = imageData.base64EncodedString()
        
        // Create schema for structured output
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "questions": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "type": [
                                "type": "string",
                                "enum": ["multiple_choice", "fill_in_blanks", "matching"]
                            ],
                            "question": ["type": "string"],
                            "options": [
                                "type": "array",
                                "items": ["type": "string"]
                            ],
                            "matchingOptions": [
                                "type": "array",
                                "items": ["type": "string"]
                            ],
                            "correctAnswer": ["type": "string"],
                            "explanation": ["type": "string"],
                            "hint": [
                                "type": ["string", "null"]  // hint can be null
                            ]
                        ],
                        "required": [
                            "type",
                            "question",
                            "options",
                            "matchingOptions",
                            "correctAnswer",
                            "explanation",
                            "hint"  // added hint to required fields
                        ],
                        "additionalProperties": false
                    ]
                ]
            ],
            "required": ["questions"],
            "additionalProperties": false
        ]
        
        // System prompt for better question generation
        let systemPrompt = """
        You are an expert tutor creating educational questions based on images.
        Generate questions that are clear, engaging, and appropriate for the given subject and difficulty level.
        For each question, you must provide:
        - A clear question text
        - Appropriate options for the question type
        - A correct answer
        - A helpful explanation
        - A hint (can be null if not applicable)
        Ensure all responses strictly follow the provided schema format.
        """
        
        // User prompt for specific requirements
        let userPrompt = """
        Generate questions based on the image with the following requirements:
        Subject: \(subject.rawValue)
        Difficulty: \(difficulty.rawValue)
        Question counts:
        \(questionTypes.map { "- \($0.key.rawValue): \($0.value)" }.joined(separator: "\n"))
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
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "question_generation",
                    "strict": true,
                    "schema": schema
                ]
            ]
        ]
        
        // URL 요청 생성
        guard let url = URL(string: baseURL) else {
            throw NetworkError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("""
        🌐 API Request:
        • URL: \(baseURL)
        • Method: POST
        • Image Size: \(imageData.count) bytes
        • Question Types: \(questionTypes)
        """)
        
        let (data, response) = try await session.data(for: request)
        
        // 응답 로깅 추가
        if let httpResponse = response as? HTTPURLResponse {
            print("""
            🌐 API Response:
            • Status Code: \(httpResponse.statusCode)
            • Headers: \(httpResponse.allHeaderFields)
            """)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw NetworkError.apiError(errorResponse.error.message)
            }
            throw NetworkError.invalidResponse
        }
        
        let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        if let content = decodedResponse.choices.first?.message.content,
           let jsonData = content.data(using: .utf8) {
            let schema = try JSONDecoder().decode(QuestionGenerationSchema.self, from: jsonData)
            
            print("""
            ✅ Questions Generated:
            • Count: \(schema.questions.count)
            • Types: \(Dictionary(grouping: schema.questions, by: { $0.type }).map { "\($0.key): \($0.value.count)" })
            """)
            
            return schema.questions.map { questionData in
                Question(
                    id: UUID().uuidString,
                    type: QuestionType(rawValue: questionData.type) ?? .multipleChoice,
                    subject: subject,
                    difficulty: difficulty,
                    question: questionData.question,
                    options: questionData.options,
                    matchingOptions: questionData.matchingOptions,
                    correctAnswer: questionData.correctAnswer,
                    explanation: questionData.explanation,
                    hint: questionData.hint,
                    isSaved: false,
                    createdAt: Date()
                )
            }
        }
        
        throw NetworkError.invalidData
    }
    
    // 세션 정리를 위한 메서드 추가
    func cleanup() {
        session.invalidateAndCancel()
    }
}
