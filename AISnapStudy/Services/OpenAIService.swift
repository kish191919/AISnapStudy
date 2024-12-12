import Foundation
import UIKit

class OpenAIService {
    // private 저장 프로퍼티 수정
    private var apiKey: String?
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    private let cache = NSCache<NSString, NSArray>()
    private let keyServerURL = "https://aistockadvisor.net/api/get-api-key"
    
    // 싱글톤 수정
    static let shared = OpenAIService()
    
    // 단일 초기화 메서드
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        self.session = URLSession(configuration: configuration)
        
        // 초기화 시점에 API Key 가져오기
        Task {
            try? await fetchAPIKey()
        }
    }
    
    private func makeOpenAIRequest(_ request: inout URLRequest) throws {
        guard let apiKey = self.apiKey else {
            print("❌ API key is nil")
            throw NetworkError.apiError("API key not available")
        }
        
        // Debug 로그 추가
        print("Debug - Raw API Key value:", apiKey)
        print("Debug - API Key type:", type(of: apiKey))
        print("Debug - API Key length:", apiKey.count)
        
        // String 리터럴로 헤더 생성
        let authHeaderValue = "Bearer " + apiKey
        request.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        
        // Debug: 실제 전송되는 헤더 값 확인
        print("Debug - Final Authorization header:", String(authHeaderValue.prefix(20)), "...")
    }

    
    // fetchAPIKey 함수 수정
    func fetchAPIKey() async throws {
        let request = URLRequest(url: URL(string: keyServerURL)!)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let keyResponse = try decoder.decode(APIKeyResponse.self, from: data)
        
        // API 키 저장 전 확인
        print("Debug - Received API Key (first 10 chars):", keyResponse.apiKey.prefix(10))
        
        // API 키 저장
        self.apiKey = keyResponse.apiKey
    }
    
    // API Key가 없을 경우 가져오는 메서드
    private func ensureValidAPIKey() async throws {
        if apiKey == nil {
            try await fetchAPIKey()
        }
    }
    
    func cleanup() {
           apiKey = nil
       }
    
    func sendTextExtractionResult(_ extractedText: String) async throws -> String {
        // API Key 확인
        try await ensureValidAPIKey()
        
        print("🔄 Processing extracted text in OpenAI service...")
        print("📝 Input text: \(extractedText)")
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        
        try makeOpenAIRequest(&request)  // API Key 설정

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": "You are an expert at analyzing extracted text."],
                ["role": "user", "content": extractedText]
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🌐 Sending request to OpenAI API...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response received")
            throw NetworkError.invalidResponse
        }
        
        print("📡 Response status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ API request failed with status code: \(httpResponse.statusCode)")
            throw NetworkError.apiError("API request failed with status \(httpResponse.statusCode)")
        }

        let result = String(data: data, encoding: .utf8) ?? "No response"
        print("✅ OpenAI processing completed: \(result)")
        return result
    }


        func sendImageDataToOpenAI(_ imageData: Data) async throws {
            // API Key 확인
            try await ensureValidAPIKey()
            
            let url = URL(string: "https://api.openai.com/v1/images")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(apiKey ?? "")", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "image": imageData.base64EncodedString(),
                "purpose": "image-analysis"
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get valid response from OpenAI API"])
            }

            let result = String(data: data, encoding: .utf8) ?? "No response"
            print("✅ Image sent to OpenAI. Response: \(result)")
        }
    
    // MARK: - Models
    public struct QuestionInput {    // private -> public 으로 변경
        let content: Data
        let isImage: Bool
        let contentHash: String
        
        public init(content: Data, isImage: Bool) {  // public init 추가
            self.content = content
            self.isImage = isImage
            self.contentHash = content.hashValue.description
        }
    }
    
    public struct QuestionParameters {    // private -> public 으로 변경
        let subject: DefaultSubject  // Subject -> DefaultSubject로 변경
        let educationLevel: EducationLevel
        let questionTypes: [QuestionType: Int]
        let language: Language
        
        public init(    // public init 추가
            subject: DefaultSubject,
            educationLevel: EducationLevel,
            questionTypes: [QuestionType: Int],
            language: Language
        ) {
            self.subject = subject
            self.educationLevel = educationLevel
            self.questionTypes = questionTypes
            self.language = language
        }
    }
    private func buildMessages(input: QuestionInput, prompts: (system: String, user: String)) -> [[String: Any]] {
        if input.isImage {
            do {
                guard let image = UIImage(data: input.content) else {
                    print("❌ Failed to create UIImage from data")
                    throw NetworkError.invalidData
                }

                let compressedData = try ImageService.shared.compressForAPI(image)
                let base64ImageString = compressedData.base64EncodedString()
                
                print("📸 Image prepared: \(ByteCountFormatter.string(fromByteCount: Int64(compressedData.count), countStyle: .file))")
                
                return [
                    ["role": "system", "content": prompts.system],
                    ["role": "user", "content": [
                        [
                            "type": "text",
                            "text": prompts.user
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64ImageString)"
                            ]
                        ]
                    ]]
                ]
            } catch {
                print("❌ Error preparing image: \(error)")
                return []
            }
        } else {
            if let textContent = String(data: input.content, encoding: .utf8) {
                return [
                    ["role": "system", "content": prompts.system],
                    ["role": "user", "content": [
                        [
                            "type": "text",
                            "text": "\(prompts.user)\n\nText data: \(textContent)"
                        ]
                    ]]
                ]
            }
            return []
        }
    }

    // extractCompleteQuestion 함수도 추가
    private func extractCompleteQuestion(from json: String) throws -> QuestionGenerationSchema.QuestionData? {
        guard let jsonData = json.data(using: .utf8) else {
            return nil
        }
        
        // JSON이 완전한 객체인지 확인
        guard json.contains("}") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let questionData = try decoder.decode(QuestionGenerationSchema.QuestionData.self, from: jsonData)
            return questionData
        } catch {
            // JSON이 아직 완성되지 않았거나 파싱할 수 없는 경우
            return nil
        }
    }
    
    // 나머지 private 구조체들은 그대로 유지
    private struct SubjectPrompt {
        let systemPrompt: String
        let userPromptTemplate: String
    }
    
    private enum OpenAIModel {
        static let gpt4Vision = "gpt-4o"
        static let maxTokens = 4000
    }
    
    // MARK: - Main Question Generation Method
    func generateQuestions(
        from input: QuestionInput,
        parameters: QuestionParameters
    ) async throws -> [Question] {
        // 네트워크 연결 확인
        guard NetworkMonitor.shared.isReachable else {
            throw NetworkError.noConnection
        }
        
        // 캐시 확인
        let cacheKey = "\(input.contentHash)_\(parameters.subject.rawValue)"
        if let cachedQuestions = cache.object(forKey: cacheKey as NSString) as? [Question] {
            print("✅ Retrieved questions from cache")
            return cachedQuestions
        }
        
        // API 키 확인 및 로깅
        guard let apiKey = self.apiKey else {
            print("❌ API key is nil")
            throw NetworkError.apiError("API key not available")
        }
        print("Debug - API Key type:", type(of: apiKey))
        print("Debug - API Key length:", apiKey.count)
        
        return try await withThrowingTaskGroup(of: Any.self) { group -> [Question] in
            var processedInput: Data?
            var processedTextInput: String?
            var preparedData: (schema: [String: Any], prompts: (system: String, user: String))?

            // 이미지 또는 텍스트를 처리하는 태스크 추가
            group.addTask(priority: .userInitiated) {
                if input.isImage {
                    processedInput = input.content
                } else {
                    processedTextInput = String(data: input.content, encoding: .utf8) ?? ""
                }
            }

            group.addTask(priority: .userInitiated) {
                return try await self.preparePromptAndSchema(input: input, parameters: parameters)
            }

            for try await result in group {
                if let schemaResult = result as? ([String: Any], (String, String)) {
                    preparedData = schemaResult
                }
            }

            guard let prepared = preparedData else {
                throw NetworkError.invalidData
            }

            // API 키를 명시적으로 전달
            let questions = try await self.performQuestionGeneration(
                input: processedInput,
                textInput: processedTextInput,
                schema: prepared.schema,
                systemPrompt: prepared.prompts.system,
                userPrompt: prepared.prompts.user,
                parameters: parameters,
                apiKey: apiKey  // API 키 전달
            )

            self.cache.setObject(questions as NSArray, forKey: cacheKey as NSString)
            return questions
        }
    }
    
    // MARK: - Subject-Specific Prompts
    private func getSubjectPrompt(
        _ subject: SubjectType,
        isImageInput: Bool,
        isExtractedText: Bool,  // 새로운 매개변수 추가
        educationLevel: EducationLevel,
        language: Language
    ) -> SubjectPrompt {
        let subjectName = if let customSubject = subject as? CustomSubject {  // 수정된 부분
            customSubject.displayName
        } else {
            subject.displayName
        }
        
        let languageInstructionText = language == .auto ?
            "Generate questions in the exact same language as the input text." :
            """
            IMPORTANT: All generated questions, answers, explanations, and hints must be in \(language.codeName).
            DO NOT use the input text's language. Even if the input is in another language, the output must be in \(language.codeName) only.
            """
        
        let languageInstructionImage = language == .auto ?
            "Generate questions in the same language as any visible text in the image." :
            """
            IMPORTANT: All generated questions, answers, explanations, and hints must be in \(language.codeName).
            DO NOT use the language of visible text in the image. All output must be in \(language.codeName) only.
            """

        // 순수 이미지 기반 입력
        if isImageInput && !isExtractedText {
            return SubjectPrompt(
                systemPrompt: """
                    You are an expert in creating self-contained, image-based questions.
                    
                    STRICT LANGUAGE REQUIREMENTS:
                    - Output language: \(language == .auto ? "same as visible text in the image" : language.codeName)
                    - Ensure consistent language usage throughout all content.
                    - Translate concepts accurately without losing meaning.
                    
                    FORMATTING REQUIREMENTS:
                    - Each question must be self-contained with all necessary context provided.
                    - Avoid ambiguous or overly broad questions.
                    - True/False answers must be "true" or "false" (lowercase).

                    ERROR PREVENTION:
                    - Check the consistency of technical terms and proper nouns.
                    """,
                userPromptTemplate: """
                    Create high-quality, context-rich questions based on the given image.
                    \(languageInstructionImage)
                    Each question must include detailed explanations and hints.

                    Examples of good questions:
                    - "If the sum of the angles in a triangle is 180°, and one angle is 90°, what are the other two angles?"
                    - "The Roman Empire declined for many reasons. Which of the following factors contributed the most to its fall?"
                    
                    Examples of bad questions:
                    - "What does the text explain?"
                    - "Is this image interesting?"
                    """
            )
        }
        // 이미지에서 추출된 텍스트 기반 입력
        else if isImageInput && isExtractedText {
            return SubjectPrompt(
                systemPrompt: """
                    You are an expert in creating self-contained questions based on extracted text from images.
                    
                    STRICT LANGUAGE REQUIREMENTS:
                    - Output language: \(language == .auto ? "same as the extracted text" : language.codeName)
                    - Maintain consistent language usage across all questions, answers, and explanations.
                    - Preserve technical terms and proper nouns during translation.

                    FORMATTING REQUIREMENTS:
                    - Create questions with all necessary context included.
                    - True/False answers must be "true" or "false" (lowercase).
                    - Avoid "wh-" questions like "what", "who", or "how".

                    ERROR PREVENTION:
                    - Check the consistency of technical terms and proper nouns.
                    """,
                userPromptTemplate: """
                    Generate accurate and context-aware questions from the extracted text in the image.
                    \(languageInstructionImage)
                    Include hints and explanations for each question.

                    Examples of good questions:
                    - "The fall of the Roman Empire is often attributed to external invasions. Which of the following best explains this?"
                    - "In the Pythagorean theorem, if a² + b² = c², what does 'c' represent in a right triangle?"

                    Examples of bad questions:
                    - "What does this text mean?"
                    - "Explain the context."
                    """
            )
        }
        // 텍스트 기반 입력
        else {
            return SubjectPrompt(
                systemPrompt: """
                    You are an expert in creating questions for \(educationLevel.displayName) students.
                    
                    STRICT LANGUAGE REQUIREMENTS:
                    - Output language: \(language == .auto ? "same as input text" : language.codeName)
                    - Maintain consistent language usage across all questions, answers, and explanations.
                    - Preserve technical terms and proper nouns during translation.
                    
                    FORMATTING REQUIREMENTS:
                    - Include all necessary context within the questions.
                    - Avoid overly broad or simplistic questions.
                    - True/False answers must be "true" or "false" (lowercase).

                    ERROR PREVENTION:
                    - Check the consistency of technical terms and proper nouns.
                    """,
                userPromptTemplate: """
                    Create thoughtful and context-rich questions based on the input text.
                    \(languageInstructionText)
                    Create National Assessment of Educational Progress questions for \(educationLevel.displayName) school students
                    Include hints and detailed explanations.

                    Examples of good questions:
                    - "The Renaissance was a cultural movement in Europe. Which of the following innovations was NOT developed during this period?"
                    - "If a car travels 60 miles in one hour, how far will it travel in three hours at the same speed?"

                    Examples of bad questions:
                    - "What is the capital of France?"
                    - "Explain this text."
                    """
            )
        }
    }

    
    // MARK: - Schema and Prompt Preparation
    private func preparePromptAndSchema(
        input: QuestionInput,
        parameters: QuestionParameters
    ) async throws -> ([String: Any], (String, String)) {
        // Add validation for required question counts
        let requiredCounts = parameters.questionTypes
        let subjectPrompt = getSubjectPrompt(
            parameters.subject,
            isImageInput: input.isImage,
            isExtractedText: !input.isImage && input.content.count > 0,  // 텍스트 추출 여부 확인
            educationLevel: parameters.educationLevel,
            language: parameters.language
        )
        let schema = try await generateSchema(for: parameters.questionTypes)
        
        let systemPrompt = """
            \(subjectPrompt.systemPrompt)
            Required question distribution:
                \(requiredCounts.map { "- \($0.key.rawValue): \($0.value) questions" }.joined(separator: "\n\t"))
            """
        
        let userPrompt = subjectPrompt.userPromptTemplate
            .replacingOccurrences(of: "{input_type}", with: input.isImage ? "image" : "text")
            .replacingOccurrences(of: "{education_level}", with: parameters.educationLevel.rawValue)
        
        return (schema, (systemPrompt, userPrompt))
    }
    
    // MARK: - Schema Generation
    private func generateSchema(for questionTypes: [QuestionType: Int]) async throws -> [String: Any] {
        let questionTypeEnums = questionTypes.keys.map { $0.rawValue }
        
        return [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "questions": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "properties": [
                            "type": ["type": "string", "enum": questionTypeEnums],
                            "question": ["type": "string"],
                            "options": [
                                "type": "array",
                                "items": [
                                    "type": "string"
                                ],
                                "description": "For true_false type, must be exactly ['true', 'false']"
                            ],
                            "correctAnswer": ["type": "string"],
                            "explanation": ["type": "string"],
                            "hint": ["type": "string"]
                        ],
                        "required": ["type", "question", "options", "correctAnswer", "explanation", "hint"]
                    ]
                ]
            ],
            "required": ["questions"]
        ]
    }
    private func performQuestionGeneration(
        input: Data?,
        textInput: String?,
        schema: [String: Any],
        systemPrompt: String,
        userPrompt: String,
        parameters: QuestionParameters,
        apiKey: String  // API 키 매개변수 추가
    ) async throws -> [Question] {
        print("🤖 OpenAI Prompt Information:")
        print("\nSystem Prompt:\n-------------\n\(systemPrompt)")
        print("\nUser Prompt:\n-----------\n\(userPrompt)")

        // messages 배열을 미리 선언
        var messages: [[String: Any]]

        // 구조화된 메시지 생성
        if let imageData = input {
            guard let image = UIImage(data: imageData) else {
                throw NetworkError.invalidData
            }

            let compressedImageData = try ImageService.shared.compressForAPI(image)
            let base64ImageString = compressedImageData.base64EncodedString()
            
            print("Compressed and Encoded Image (Base64) Size: \(base64ImageString.count) characters")

            // OpenAI 공식 멀티모달 포맷 사용
            messages = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    [
                        "type": "text",
                        "text": userPrompt
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64ImageString)"
                        ]
                    ]
                ]]
            ]
        } else if let textData = textInput {
            messages = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    [
                        "type": "text",
                        "text": "\(userPrompt)\n\nText data: \(textData)"
                    ]
                ]]
            ]
        } else {
            throw NetworkError.invalidData
        }

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
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        
        // API 키를 직접 사용하여 Authorization 헤더 설정
        let authHeaderValue = "Bearer " + apiKey
        request.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Debug: 헤더 확인
        print("Debug - Final Authorization header:", String(authHeaderValue.prefix(20)), "...")
        
        print("""
        🌐 API Request:
        • URL: \(baseURL)
        • Method: POST
        • Content Type: \(request.value(forHTTPHeaderField: "Content-Type") ?? "none")
        """)

        let (data, response) = try await session.data(for: request)

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

        guard let content = decodedResponse.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
            throw NetworkError.invalidData
        }

        let questionSchema = try JSONDecoder().decode(QuestionGenerationSchema.self, from: jsonData)

        let questions = questionSchema.questions.map { questionData in
            // True/False 질문에서 접두사 제거
            let processedQuestion = questionData.type == "true_false" ?
                questionData.question
                    .replacingOccurrences(
                        of: "^(True or False:|True/False:|T/F:|\\(True/False\\)|\\[True/False\\]|True or False\\?|Is it true or false:|True False:)\\s*",
                        with: "",
                        options: [.regularExpression, .caseInsensitive]
                    )
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .replacingOccurrences(of: "\n+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines) :
                questionData.question
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .replacingOccurrences(of: "\n+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

            // True/False 답변 정규화
            var correctAnswer = questionData.correctAnswer
            if questionData.type == "true_false" {
                correctAnswer = correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if ["yes", "네", "true", "correct", "that's right", "맞습니다", "네, 그렇습니다", "사실입니다"].contains(correctAnswer) {
                    correctAnswer = "true"
                } else if ["no", "아니오", "false", "incorrect", "that's wrong", "아닙니다", "아니요", "사실이 아니다", "사실이 아닙니다"].contains(correctAnswer) {
                    correctAnswer = "false"
                }
            }

            return Question(
                id: UUID().uuidString,
                type: QuestionType(rawValue: questionData.type) ?? .multipleChoice,
                subject: parameters.subject,
                question: processedQuestion,
                options: questionData.options,
                correctAnswer: correctAnswer,
                explanation: questionData.explanation,
                hint: questionData.hint,
                isSaved: false,
                createdAt: Date()
            )
        }

        print("""
        ✅ Questions Generated:
        • Count: \(questions.count)
        • Types: \(Dictionary(grouping: questions, by: { $0.type }).map { "\($0.key): \($0.value.count)" })
        """)

        return questions
    }
    
}


struct APIKeyResponse: Codable {
    let apiKey: String
    
    // CodingKeys 추가
    enum CodingKeys: String, CodingKey {
        case apiKey = "apiKey"
    }
}

