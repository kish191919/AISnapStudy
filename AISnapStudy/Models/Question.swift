

import Foundation

public enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case trueFalse = "true_false"  
}

public struct Question: Identifiable, Codable {
    public let id: String
    public let type: QuestionType
    public let subject: Subject
    public let difficulty: Difficulty
    public let question: String
    public let options: [String]
    public let correctAnswer: String
    public let explanation: String
    public let hint: String?
    public var isSaved: Bool
    public let createdAt: Date
    
    public init(
        id: String,
        type: QuestionType,
        subject: Subject,
        difficulty: Difficulty,
        question: String,
        options: [String] = [],
        correctAnswer: String,
        explanation: String,
        hint: String? = nil,
        isSaved: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.subject = subject
        self.difficulty = difficulty
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.hint = hint
        self.isSaved = isSaved
        self.createdAt = createdAt
    }
}

// MARK: - QuestionData for NSSecureCoding
public class QuestionData: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    let question: Question
    
    init(question: Question) {
        self.question = question
        super.init()
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(question.id, forKey: "id")
        coder.encode(question.type.rawValue, forKey: "type")
        coder.encode(question.subject.rawValue, forKey: "subject")
        coder.encode(question.difficulty.rawValue, forKey: "difficulty")
        coder.encode(question.question, forKey: "question")
        coder.encode(question.options, forKey: "options")
        coder.encode(question.correctAnswer, forKey: "correctAnswer")
        coder.encode(question.explanation, forKey: "explanation")
        coder.encode(question.hint, forKey: "hint")
        coder.encode(question.isSaved, forKey: "isSaved")
        coder.encode(question.createdAt, forKey: "createdAt")
    }
    
    public required init?(coder: NSCoder) {
        guard let id = coder.decodeObject(of: NSString.self, forKey: "id") as String?,
              let typeRaw = coder.decodeObject(of: NSString.self, forKey: "type") as String?,
              let subjectRaw = coder.decodeObject(of: NSString.self, forKey: "subject") as String?,
              let difficultyRaw = coder.decodeObject(of: NSString.self, forKey: "difficulty") as String?,
              let questionText = coder.decodeObject(of: NSString.self, forKey: "question") as String?,
              let options = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "options") as? [String],
              let correctAnswer = coder.decodeObject(of: NSString.self, forKey: "correctAnswer") as String?,
              let explanation = coder.decodeObject(of: NSString.self, forKey: "explanation") as String? else {
            return nil
        }
        
        let hint = coder.decodeObject(of: NSString.self, forKey: "hint") as String?
        let isSaved = coder.decodeBool(forKey: "isSaved")
        let createdAt = coder.decodeObject(of: NSDate.self, forKey: "createdAt") as Date? ?? Date()
        
        let question = Question(
            id: id,
            type: QuestionType(rawValue: typeRaw) ?? .multipleChoice,
            subject: Subject(rawValue: subjectRaw) ?? .math,
            difficulty: Difficulty(rawValue: difficultyRaw) ?? .medium,
            question: questionText,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanation,
            hint: hint,
            isSaved: isSaved,
            createdAt: createdAt
        )
        
        self.question = question
        super.init()
    }
}

// MARK: - Hashable
extension Question: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Question, rhs: Question) -> Bool {
        lhs.id == rhs.id
    }
}
