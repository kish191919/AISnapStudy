import Foundation

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
            group.addTask(priority: .userInitiated) {
                if input.isImage {
                    return try await self.processImage(input.content)
                } else {
                    return String(data: input.content, encoding: .utf8) ?? ""
                }
            }
            
            group.addTask(priority: .userInitiated) {
                return try await self.preparePromptAndSchema(
                    input: input,
                    parameters: parameters
                )
            }
            
            var processedInput: String?
            var preparedData: (schema: [String: Any], prompts: (system: String, user: String))?
            
            for try await result in group {
                if let inputResult = result as? String {
                    processedInput = inputResult
                } else if let schemaResult = result as? ([String: Any], (String, String)) {
                    preparedData = schemaResult
                }
            }
            
            guard let input = processedInput,
                  let prepared = preparedData else {
                throw NetworkError.invalidData
            }
            
            let questions = try await self.performQuestionGeneration(
                input: input,
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
        private func getSubjectPrompt(_ subject: Subject) -> SubjectPrompt {
            switch subject {
            case .language:
                return SubjectPrompt(
                    systemPrompt: """
                    You are an expert language educator creating questions that assess:
                    - Basic comprehension and detail retention
                    - Inference and interpretation abilities
                    - Cause and effect relationships
                    - Term definitions and usage
                    - Comparison and contrast skills
                    - Application of concepts
                    - Critical thinking development
                    Create questions that challenge students' understanding while maintaining clarity.
                    """,
                    userPromptTemplate: """
                    Analyze the {input_type} and use {input_type} to create questions that evaluate:
                    1. Text comprehension and interpretation
                    2. Key details and main ideas
                    3. Vocabulary and language patterns
                    4. Critical analysis and reasoning
                    5. Practical application of language concepts
                    Must create questions using the same language as the language of the picture you read or the language of the text you enter.
                    Questions must to be made at a level that {education_level} school student would find {difficulty} to solve.
                    """
                )
                
            case .math:
                return SubjectPrompt(
                    systemPrompt: """
                    You are an expert mathematics educator creating questions that assess:
                    - Operational understanding
                    - Pattern recognition
                    - Problem-solving abilities
                    - Arithmetic reasoning
                    - Concept application
                    - Number decomposition and composition
                    Create questions that test both procedural fluency and conceptual understanding.
                    """,
                    userPromptTemplate: """
                    Analyze the {input_type} and use {input_type} to create questions that evaluate:
                    1. Mathematical concept understanding
                    2. Computational skills
                    3. Problem-solving strategies
                    4. Pattern recognition abilities
                    5. Application of mathematical principles
                    Must create questions using the same language as the language of the picture you read or the language of the text you enter.
                    Questions must to be made at a level that {education_level} school student would find {difficulty} to solve.
                    """
                )
                
            case .geography:
                return SubjectPrompt(
                    systemPrompt: """
                    You are an expert geography educator creating questions that assess:
                    - Location and direction understanding
                    - Physical features and characteristics
                    - Climate and weather patterns
                    - Natural resources and economic activities
                    - Population and cultural diversity
                    - Environmental issues and sustainability
                    Create questions that develop geographical thinking and spatial awareness.
                    """,
                    userPromptTemplate: """
                    Analyze the {input_type} and use {input_type} to create questions that evaluate:
                    1. Geographical features and patterns
                    2. Spatial relationships
                    3. Environmental processes
                    4. Human-environment interaction
                    5. Cultural and economic geography
                    Must create questions using the same language as the language of the picture you read or the language of the text you enter.
                    Questions must to be made at a level that {education_level} school student would find {difficulty} to solve.
                    """
                )
                
            case .history:
                return SubjectPrompt(
                    systemPrompt: """
                    You are an expert history educator creating questions that assess:
                    - Cause and effect relationships
                    - Chronological understanding
                    - Historical figures and achievements
                    - Cultural and social changes
                    - Political ideologies and institutions
                    - Long-term impacts and legacy
                    Create questions that develop historical thinking and critical analysis.
                    """,
                    userPromptTemplate: """
                    Analyze the {input_type} and use {input_type} to create questions that evaluate:
                    1. Historical events and their significance
                    2. Cause and effect relationships
                    3. Historical perspectives and contexts
                    4. Change and continuity over time
                    5. Historical evidence and interpretation
                    Must create questions using the same language as the language of the picture you read or the language of the text you enter.
                    Questions must to be made at a level that {education_level} school student would find {difficulty} to solve.
                    """
                )
                
            case .science:
                return SubjectPrompt(
                    systemPrompt: """
                    You are an expert science educator creating questions that assess:
                    - Basic concept understanding
                    - Scientific method and procedures
                    - Data analysis and interpretation
                    - Cause and effect relationships
                    - Experimental design
                    - Application of scientific principles
                    Create questions that develop scientific thinking and inquiry skills.
                    """,
                    userPromptTemplate: """
                    Analyze the {input_type} and use {input_type} to create questions that evaluate:
                    1. Scientific concepts and principles
                    2. Experimental processes
                    3. Data interpretation
                    4. Scientific reasoning
                    5. Real-world applications
                    Must create questions using the same language as the language of the picture you read or the language of the text you enter.
                    Questions must to be made at a level that {education_level} school student would find {difficulty} to solve.
                    """
                )
                
            case .generalKnowledge:
                return SubjectPrompt(
                    systemPrompt: """
                    You are an expert educator creating questions that assess:
                    - Basic concept understanding
                    - Analysis and interpretation
                    - Critical thinking and evaluation
                    - Problem solving abilities
                    - Real-world applications
                    - Creative thinking
                    Create engaging questions that test broad knowledge and analytical skills.
                    """,
                    userPromptTemplate: """
                    Analyze the {input_type} and use {input_type} to create questions that evaluate:
                    1. General knowledge and understanding
                    2. Critical thinking and analysis
                    3. Problem-solving abilities
                    4. Real-world applications
                    5. Interconnected knowledge
                    
                    Must create questions using the same language as the language of the picture you read or the language of the text you enter.
                    Questions must to be made at a level that {education_level} school student would find {difficulty} to solve.
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
            let subjectPrompt = getSubjectPrompt(parameters.subject)
            let schema = try await generateSchema(for: parameters.questionTypes)
            
            let systemPrompt = """
            \(subjectPrompt.systemPrompt)
            
            Generate questions that are:
            - Appropriate for \(parameters.educationLevel.rawValue) school student level
            - At \(parameters.difficulty.rawValue) difficulty
            - Clear and unambiguous
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
        
        // MARK: - Helper Methods
        private func processImage(_ imageData: Data) async throws -> String {
            return imageData.base64EncodedString()
        }
        
        private func performQuestionGeneration(
            input: String,
            schema: [String: Any],
            systemPrompt: String,
            userPrompt: String,
            parameters: QuestionParameters
        ) async throws -> [Question] {
            print("""
             🤖 OpenAI Prompt Information:
             
             System Prompt:
             -------------
             \(systemPrompt)
             
             User Prompt:
             -----------
             \(parameters.subject == .generalKnowledge ? userPrompt : "\(userPrompt)\n\nInput: \(input)")
             
             Question Types Required:
             ----------------------
             \(parameters.questionTypes.map { "• \($0.key.rawValue): \($0.value)" }.joined(separator: "\n"))
             """)
            
            let messages: [[String: Any]] = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": parameters.subject == .generalKnowledge ?
                    userPrompt : "\(userPrompt)\n\nInput: \(input)"]
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

            
            let requestData = try JSONSerialization.data(withJSONObject: requestBody)
            
            var request = URLRequest(url: URL(string: baseURL)!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestData
            
            let (data, response) = try await session.data(for: request)
            
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
            
        }
        
        func cleanup() {
            session.invalidateAndCancel()
            cache.removeAllObjects()
        }
    }
