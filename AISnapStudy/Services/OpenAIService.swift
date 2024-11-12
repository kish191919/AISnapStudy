import AISnapStudy
import Foundation

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    private let cache = NSCache<NSString, NSArray>()
    
    // OpenAI 모델 상수 정의
    private enum OpenAIModel {
        static let gpt4Vision = "gpt-4o"
        static let maxTokens = 4000
    }
    
    init() throws {
        self.apiKey = try ConfigurationManager.shared.getValue(for: "OpenAIAPIKey")
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
        educationLevel: EducationLevel,
        questionTypes: [QuestionType: Int]
    ) async throws -> [Question] {
        // 네트워크 연결 확인
        guard NetworkMonitor.shared.isReachable else {
            throw NetworkError.noConnection
        }
        
        // 캐시 확인
        let imageHash = imageData.hashValue.description
        let cacheKey = "\(imageHash)_\(subject.rawValue)_\(difficulty.rawValue)"
        if let cachedQuestions = cache.object(forKey: cacheKey as NSString) as? [Question] {
            print("✅ Retrieved questions from cache")
            return cachedQuestions
        }
        
        return try await withThrowingTaskGroup(of: Any.self) { group -> [Question] in
            // 1. 이미지 처리 Task
            group.addTask(priority: .userInitiated) {
                return try await self.processImage(imageData)
            }
            
            // 2. 스키마 및 프롬프트 준비 Task
            group.addTask(priority: .userInitiated) {
                return try await self.prepareSchemaAndPrompts(
                    subject: subject,
                    difficulty: difficulty,
                    educationLevel: educationLevel,
                    questionTypes: questionTypes
                )
            }
            
            // 결과 수집
            var base64Image: String?
            var preparedData: (schema: [String: Any], prompts: (system: String, user: String))?
            
            for try await result in group {
                if let imageResult = result as? String {
                    base64Image = imageResult
                } else if let schemaResult = result as? ([String: Any], (String, String)) {
                    preparedData = schemaResult
                }
            }
            
            guard let image = base64Image,
                  let prepared = preparedData else {
                throw NetworkError.invalidData
            }
            
            // API 요청 준비
            let requestData = try await prepareRequestBody(
                image: image,
                schema: prepared.schema,
                systemPrompt: prepared.prompts.system,
                userPrompt: prepared.prompts.user
            )
            
            let questions = try await performRequest(
                with: requestData,
                subject: subject,
                difficulty: difficulty
            )
            
            // 캐시에 결과 저장
            cache.setObject(questions as NSArray, forKey: cacheKey as NSString)
            
            return questions
        }
    }
    
    private func processImage(_ imageData: Data) async throws -> String {
        return try await Task.detached(priority: .userInitiated) {
            // Data를 직접 base64로 변환
            return imageData.base64EncodedString()
        }.value
    }

    
    private func prepareSchemaAndPrompts(
        subject: Subject,
        difficulty: Difficulty,
        educationLevel: EducationLevel,
        questionTypes: [QuestionType: Int]
    ) async throws -> ([String: Any], (String, String)) {
        let questionTypeEnums = ["multiple_choice", "fill_in_blanks", "matching", "true_false"]
        let schema: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "questions": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "properties": [
                            "type": [
                                "type": "string",
                                "enum": questionTypeEnums
                            ],
                            "question": [
                                "type": "string"
                            ],
                            "options": [
                                "type": "array",
                                "items": ["type": "string"]
                            ],
                            "matchingOptions": [
                                "type": "array",
                                "items": ["type": "string"]
                            ],
                            "correctAnswer": [
                                "type": "string"
                            ],
                            "explanation": [
                                "type": "string"
                            ],
                            "hint": [
                                "type": "string"
                            ]
                        ],
                        "required": [
                            "type",
                            "question",
                            "options",
                            "matchingOptions",
                            "correctAnswer",
                            "explanation",
                            "hint"
                        ]
                    ]
                ]
            ],
            "required": ["questions"]
        ]
        
        // questionTypes Dictionary를 문자열로 변환
        let questionCountsText = questionTypes
            .map { type, count in
                "- \(type.rawValue): \(count)"
            }
            .joined(separator: "\n")
        
            let systemPrompt = """
            You are an expert tutor creating educational questions based on images.
            Generate questions that are clear, engaging, and appropriate for the given subject and difficulty level.
            For each question, you must provide:
            - A clear question text
            - Appropriate options for the question type
            - A correct answer
            - A helpful explanation
            - A hint (can be null if not applicable)
            Ensure all responses strictly follow the provided schema format and create questions using the language written in the photo
            """

            let userPrompt = """
            Generate questions based on the image with the following requirements:
            Subject: \(subject.rawValue)
            Education: \(educationLevel.rawValue)
            Difficulty: \(difficulty.rawValue)
            Question counts:
            \(questionCountsText)
            """

            return (schema, (systemPrompt, userPrompt))
        }
    
    private func prepareRequestBody(
        image: String,
        schema: [String: Any],
        systemPrompt: String,
        userPrompt: String
    ) throws -> Data {
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": [
                ["type": "text", "text": userPrompt],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(image)"]]
            ]]
        ]
        
        let requestBody: [String: Any] = [
            "model": OpenAIModel.gpt4Vision,
            "max_tokens": OpenAIModel.maxTokens,
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
        
        return try JSONSerialization.data(withJSONObject: requestBody)
    }
    
    private func performRequest(
        with requestData: Data,
        subject: Subject,
        difficulty: Difficulty
    ) async throws -> [Question] {
        try await withTimeout(seconds: 30) { [weak self] in
            guard let self = self else { throw NetworkError.unknown(NSError()) }
            
            var request = URLRequest(url: URL(string: self.baseURL)!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestData
            
            let (data, response) = try await self.performRequestWithRetry(request: request)
            return try await self.processResponse(data, response, subject: subject, difficulty: difficulty)
        }
    }
    
    private func performRequestWithRetry(request: URLRequest, maxRetries: Int = 3) async throws -> (Data, URLResponse) {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await session.data(for: request)
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                }
            }
        }
        throw lastError ?? NetworkError.unknown(NSError())
    }
    
    private func processResponse(
        _ data: Data,
        _ response: URLResponse,
        subject: Subject,
        difficulty: Difficulty
    ) async throws -> [Question] {
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
        
        guard let content = decodedResponse.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
            throw NetworkError.invalidData
        }
        
        let questionSchema = try JSONDecoder().decode(QuestionGenerationSchema.self, from: jsonData)
        
        return questionSchema.questions.map { questionData in
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
    
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NetworkError.timeout
            }
            
            guard let result = try await group.next() else {
                throw NetworkError.unknown(NSError())
            }
            
            group.cancelAll()
            return result
        }
    }
    
    func cleanup() {
        session.invalidateAndCancel()
        cache.removeAllObjects()
    }
}
