
import Foundation

public struct ProblemSet: Identifiable, Codable {
    public let id: String
    public let title: String
    public let subject: Subject
    public let difficulty: Difficulty
    public let questions: [Question]
    public let createdAt: Date
    public var lastAttempted: Date?
    
    public var questionCount: Int {
        questions.count
    }
    
    public init(
        id: String,
        title: String,
        subject: Subject,
        difficulty: Difficulty,
        questions: [Question],
        createdAt: Date,
        lastAttempted: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.subject = subject
        self.difficulty = difficulty
        self.questions = questions
        self.createdAt = createdAt
        self.lastAttempted = lastAttempted
    }
}

// MARK: - Hashable
extension ProblemSet: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ProblemSet, rhs: ProblemSet) -> Bool {
        lhs.id == rhs.id
    }
}
