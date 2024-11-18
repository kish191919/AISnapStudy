import Foundation
import UIKit

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    private let cache = NSCache<NSString, NSArray>()
    
    static let shared: OpenAIService = {
        do {
            return try OpenAIService()
        } catch {
            fatalError("Failed to initialize OpenAIService: \(error)")
        }
    }()
    
    
    func sendTextExtractionResult(_ extractedText: String) async throws -> String {
        print("🔄 Processing extracted text in OpenAI service...")
        print("📝 Input text: \(extractedText)")
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

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
            let url = URL(string: "https://api.openai.com/v1/images")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")

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
        let subject: Subject
        let difficulty: Difficulty
        let educationLevel: EducationLevel
        let questionTypes: [QuestionType: Int]
        let language: Language
        
        public init(    // public init 추가
            subject: Subject,
            difficulty: Difficulty,
            educationLevel: EducationLevel,
            questionTypes: [QuestionType: Int],
            language: Language
        ) {
            self.subject = subject
            self.difficulty = difficulty
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
    
    // 나머지 private 구조체들은 그대로 유지
    private struct SubjectPrompt {
        let systemPrompt: String
        let userPromptTemplate: String
    }
    
    private enum OpenAIModel {
        static let gpt4Vision = "gpt-4o"
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
    private func getSubjectPrompt(
        _ subject: Subject,
        isImageInput: Bool,
        isExtractedText: Bool,  // 새로운 매개변수 추가
        educationLevel: EducationLevel,
        difficulty: Difficulty,
        language: Language
    ) -> SubjectPrompt {
        let languageInstruction_text = language == .auto ?
            "Generate questions in the exact same language as the input text" :
            """
            IMPORTANT: You must generate all questions, answers, explanations, and hints in \(language.displayName) (\(language.rawValue)) language.
            DO NOT use the input text's language.
            Even if the input is in a different language, your output must be in \(language.displayName) only.
            """
        
        let languageInstruction_image = language == .auto ?
            "Generate questions in the exact same language as any visible text in the image" :
            """
            IMPORTANT: You must generate all questions, answers, explanations, and hints in \(language.displayName) (\(language.rawValue)) language.
            DO NOT use the input text's language.
            Even if the input text is in a different language, your output must be in \(language.displayName) only.
            """

        if isImageInput && !isExtractedText {
            // 순수 이미지 분석 케이스
            return SubjectPrompt(
                systemPrompt: """
                    You are an \(subject.displayName) expert creating image-based questions.
                    Focus on creating self-contained questions that provide all necessary context within each question.
                    
                    STRICT LANGUAGE REQUIREMENT:
                    - Output language: \(language == .auto ? "Same as visible text in input" : language.displayName)
                    - Maintain consistent language throughout all content
                    - Translate concepts from input while maintaining accuracy
                    
                    For True/False questions:
                    - Answer must be exactly "true" or "false" (lowercase)
                    - Do not use variations like "Yes", "No", "That's correct", etc.
                    - Do not translate true/false to other languages
                    """,
                userPromptTemplate: """
                    Focus on creating self-contained questions that provide all necessary context within each question.
                    Important: \(languageInstruction_image)
                    Include detailed explanations and hints.
                    
                    Do not include the example questions below as part of the generated questions. These are provided only as examples of good and bad questions and must not appear in the output.
                    
                    Examples of GOOD trueFalse questions:
                    - In a perfectly competitive market, individual firms are price takers because they produce a significant portion of the total market supply.
                    - If the sum of the angles in a triangle is 180°, and one angle is 90°, then the other two angles must be 45° each.
                    
                    Examples of BAD trueFalse questions:
                    - The capital of France is Berlin.
                    - Who was worried in the story?
                    
                    Examples of GOOD multipleChoice questions:
                    - The fall of the Western Roman Empire in 476 AD is often considered a turning point in European history. Which of the following factors contributed the most to the decline of the empire?
                    - What lesson does the person mentioned in the text want to convey to us through ‘trying to endure many hardships while worrying about how to repay the mortgaged house price’
                    
                    Examples of BAD multipleChoice questions:
                    - What does the text explain?
                    - According to the text, what is his job?
                    """
            )
        } else if isImageInput && isExtractedText {
            // 이미지에서 추출된 텍스트 분석 케이스
            return SubjectPrompt(
                systemPrompt: """
                    You are an \(subject.displayName) expert analyzing extracted text from images.
                    Focus on creating self-contained questions that provide all necessary context within each question.
                    
                    STRICT LANGUAGE REQUIREMENT:
                    - Output language: \(language == .auto ? "Same as extracted text" : language.displayName)
                    - Maintain consistent language throughout all content
                    - Preserve technical terms and proper nouns while translating
                    
                    For trueFalse questions:
                    - Must be a statement that can be verified as true or false
                    - Do not create open-ended or "wh-" questions (what, who, how, etc.)
                    - Answer must be exactly "true" or "false" (lowercase)
                    - Do not use variations like "Yes", "No", "That's correct", etc.
                    - Do not translate true/false to other languages
                    """,
                userPromptTemplate: """
                    Focus on creating self-contained questions that provide all necessary context within each question.
                    Important: \(languageInstruction_image)
                    Include detailed explanations and hints.
                    
                    Do not include the example questions below as part of the generated questions. These are provided only as examples of good and bad questions and must not appear in the output.
                    
                    Examples of GOOD trueFalse questions:
                    - In a perfectly competitive market, individual firms are price takers because they produce a significant portion of the total market supply.
                    - If the sum of the angles in a triangle is 180°, and one angle is 90°, then the other two angles must be 45° each.
                    
                    Examples of BAD trueFalse questions:
                    - The capital of France is Berlin.
                    - Who was worried in the story?
                    
                    Examples of GOOD multipleChoice questions:
                    - The fall of the Western Roman Empire in 476 AD is often considered a turning point in European history. Which of the following factors contributed the most to the decline of the empire?
                    - What lesson does the person mentioned in the text want to convey to us through ‘trying to endure many hardships while worrying about how to repay the mortgaged house price’
                    
                    Examples of BAD multipleChoice questions:
                    - What does the text explain?
                    - According to the text, what is his job?
                    """
            )
        } else {
            // 일반 텍스트 입력 케이스 (기존 로직)
            return SubjectPrompt(
                systemPrompt: """
                    You are an \(subject.displayName) expert specializing in creating questions for \(educationLevel.displayName) school students.
                    Focus on creating self-contained questions that provide all necessary context within each question.
                    Include detailed explanations and hints.
                    
                    STRICT LANGUAGE REQUIREMENT:
                    - Output language: \(language == .auto ? "Same as input" : language.displayName)
                    - Maintain consistent language throughout all content
                    - Translate concepts from input while maintaining accuracy
                    
                    For True/False questions:
                    - Answer must be exactly "true" or "false" (lowercase)
                    - Do not use variations like "Yes", "No", "That's correct", etc.
                    - Do not translate true/false to other languages
                    """,
                userPromptTemplate: """
                    Focus on creating self-contained questions that provide all necessary context within each question.
                    Important: \(languageInstruction_text)
                    Include detailed explanations and hints.
                    
                    Question creation guidelines:
                    - Generate questions directly from the user's input content
                    - Create questions for \(educationLevel.displayName) school student
                    - Avoid broad, oversimplified questions
                    
                    Do not include the example questions below as part of the generated questions. These are provided only as examples of good and bad questions and must not appear in the output.

                    Examples of GOOD trueFalse questions:
                    - In a perfectly competitive market, individual firms are price takers because they produce a significant portion of the total market supply.
                    - If the sum of the angles in a triangle is 180°, and one angle is 90°, then the other two angles must be 45° each.
                    
                    Examples of BAD trueFalse questions:
                    - The capital of France is Berlin.
                    - Who was worried in the story?
                    
                    Examples of GOOD multipleChoice questions:
                    - The fall of the Western Roman Empire in 476 AD is often considered a turning point in European history. Which of the following factors contributed the most to the decline of the empire?
                    - What lesson does the person mentioned in the text want to convey to us through ‘trying to endure many hardships while worrying about how to repay the mortgaged house price’
                    
                    Examples of BAD multipleChoice questions:
                    - What does the text explain?
                    - According to the text, what is his job?
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
            difficulty: parameters.difficulty,
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
            // True/False 질문에서 접두사 제거
            let processedQuestion = questionData.type == "true_false" ?
                questionData.question.replacingOccurrences(
                    of: "^(True or False:|True/False:|T/F:)\\s*",
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                ).trimmingCharacters(in: .whitespacesAndNewlines) :
                questionData.question

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
                difficulty: parameters.difficulty,
                question: processedQuestion,
                options: questionData.options,
                correctAnswer: correctAnswer,  // 정규화된 답변 사용
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
