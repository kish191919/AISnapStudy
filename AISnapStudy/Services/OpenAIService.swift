import Foundation
import UIKit

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    private let cache = NSCache<NSString, NSArray>()
    
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
        let subject: Subject
        let difficulty: Difficulty
        let educationLevel: EducationLevel
        let questionTypes: [QuestionType: Int]
        
        public init(    // public init 추가
            subject: Subject,
            difficulty: Difficulty,
            educationLevel: EducationLevel,
            questionTypes: [QuestionType: Int]
        ) {
            self.subject = subject
            self.difficulty = difficulty
            self.educationLevel = educationLevel
            self.questionTypes = questionTypes
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
    
    // StreamResponse 구조체도 필요합니다
    private struct StreamResponse: Codable {
        struct Choice: Codable {
            struct Delta: Codable {
                let content: String?
            }
            let delta: Delta
        }
        let choices: [Choice]
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
    
    // 스트리밍을 위한 새로운 메서드 추가
    public func streamQuestions(
        from input: QuestionInput,
        parameters: QuestionParameters
    ) -> AsyncThrowingStream<Question, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    print("🔄 Starting question stream generation...")
                    let (schema, prompts) = try await preparePromptAndSchema(input: input, parameters: parameters)
                    
                    var request = URLRequest(url: URL(string: baseURL)!)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let requestBody: [String: Any] = [
                        "model": OpenAIModel.gpt4Vision,
                        "messages": buildMessages(input: input, prompts: prompts),
                        "stream": true,  // 스트리밍 활성화
                        "max_tokens": OpenAIModel.maxTokens,
                        "temperature": 0.7,
                        "response_format": ["type": "json_object"]  // JSON 응답 형식 지정
                    ]
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                    
                    print("🌐 Starting streaming request...")
                    let (result, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse
                    }
                    
                    print("📡 Stream connected with status: \(httpResponse.statusCode)")
                    
                    var questionBuffer = ""
                    var questionCount = 0
                    
                    for try await line in result.lines {
                        if line.hasPrefix("data: "), let data = line.dropFirst(6).data(using: .utf8) {
                            if let streamResponse = try? JSONDecoder().decode(StreamResponse.self, from: data),
                               let content = streamResponse.choices.first?.delta.content {
                                questionBuffer += content
                                
                                // JSON 객체가 완성되면 파싱
                                if let questionData = try? extractCompleteQuestion(from: questionBuffer) {
                                    questionCount += 1
                                    print("✅ Streaming question \(questionCount): \(questionData.question)")
                                    
                                    let question = Question(
                                        id: UUID().uuidString,
                                        type: QuestionType(rawValue: questionData.type) ?? .multipleChoice,
                                        subject: parameters.subject,
                                        difficulty: parameters.difficulty,
                                        question: questionData.question,
                                        options: questionData.options,
                                        correctAnswer: questionData.correctAnswer,
                                        explanation: questionData.explanation,
                                        hint: questionData.hint,
                                        isSaved: false,
                                        createdAt: Date()
                                    )
                                    
                                    continuation.yield(question)
                                    questionBuffer = ""
                                }
                            }
                        }
                    }
                    
                    print("✅ Stream completed: Generated \(questionCount) questions")
                    continuation.finish()
                } catch {
                    print("❌ Stream error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // 나머지 private 구조체들은 그대로 유지
    private struct SubjectPrompt {
        let systemPrompt: String
        let userPromptTemplate: String
    }
    
    private enum OpenAIModel {
        static let gpt4Vision = "gpt-4o-mini"
        static let maxTokens = 4000
    }
    
    // MARK: - Initialization
    init() throws {
        self.apiKey = try ConfigurationManager.shared.getValue(for: "OpenAIAPIKey")
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Main Question Generation Method
    func generateQuestions(
        from input: QuestionInput,
        parameters: QuestionParameters
    ) async throws -> [Question] {
        guard NetworkMonitor.shared.isReachable else {
            throw NetworkError.noConnection
        }
        
        let cacheKey = "\(input.contentHash)_\(parameters.subject.rawValue)_\(parameters.difficulty.rawValue)"
        if let cachedQuestions = cache.object(forKey: cacheKey as NSString) as? [Question] {
            print("✅ Retrieved questions from cache")
            return cachedQuestions
        }
        
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

            let questions = try await self.performQuestionGeneration(
                input: processedInput,                     // 이미지 데이터 전달
                textInput: processedTextInput,             // 텍스트 데이터 전달
                schema: prepared.schema,
                systemPrompt: prepared.prompts.system,
                userPrompt: prepared.prompts.user,
                parameters: parameters
            )

            self.cache.setObject(questions as NSArray, forKey: cacheKey as NSString)
            return questions
        }
    }
    
    // MARK: - Subject-Specific Prompts
    private func getSubjectPrompt(_ subject: Subject, isImageInput: Bool, educationLevel: EducationLevel, difficulty: Difficulty) -> SubjectPrompt {
        if isImageInput {
            return SubjectPrompt(
                systemPrompt: """
                   You are an expert \(subject.displayName) educator in generating insightful and educational questions based on image content.
                   IMPORTANT: Generate questions in the SAME LANGUAGE as any text visible in the image.
                   If the image contains Korean text, questions must be in Korean.
                   """,
                userPromptTemplate: """
                   Please analyze the uploaded image and generate questions based on its content.
                   Maintain the same language as any text found in the image.
                   """
            )
        } else {
            return SubjectPrompt(
                systemPrompt: """
                   You are an expert \(subject.displayName) educator specializing in creating questions for \(educationLevel.displayName) school students.
                   IMPORTANT: Generate questions in the EXACT SAME LANGUAGE as the input text.
                   If the input is in Korean, questions MUST be in Korean.
                   
                   Questions should:
                   - Match the specified education level (\(educationLevel.displayName))
                   - Maintain consistent \(difficulty.displayName) difficulty
                   - Preserve the input text's language
                   - Use clear, precise language appropriate for the grade level
                   - Include detailed explanations and hints
                   - Never reference any images when input is text
                   """,
                userPromptTemplate: """
                   Generate questions based on the following text. 
                   Maintain the exact same language as the input text.
                   The questions should be suitable for \(educationLevel.displayName) level students at a \(difficulty.displayName) difficulty level.
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
            educationLevel: parameters.educationLevel,
            difficulty: parameters.difficulty
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
            .replacingOccurrences(of: "{difficulty}", with: parameters.difficulty.rawValue)
        
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
                            "options": ["type": "array", "items": ["type": "string"]],
                            "correctAnswer": ["type": "string"],
                            "explanation": ["type": "string"],
                            "hint": ["type": "string"]
                        ],
                        "required": ["type", "question", "options", "correctAnswer", "explanation", "hint" ]
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
        parameters: QuestionParameters
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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

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
            Question(
                id: UUID().uuidString,
                type: QuestionType(rawValue: questionData.type) ?? .multipleChoice,
                subject: parameters.subject,
                difficulty: parameters.difficulty,
                question: questionData.question,
                options: questionData.options,
                correctAnswer: questionData.correctAnswer,
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
