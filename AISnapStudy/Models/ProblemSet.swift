
import Foundation

public struct ProblemSet: Identifiable, Codable {
    public let id: String
    public let title: String
    public let subject: Subject
    public let difficulty: Difficulty
    public let questions: [Question]
    public let createdAt: Date
    public var lastAttempted: Date?
    
    // 새로 추가할 속성들
    public let educationLevel: EducationLevel
    public var name: String
    public var tags: [String]
    public var problemSetDescription: String?
    public var isFavorite: Bool
    
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
          lastAttempted: Date? = nil,
          educationLevel: EducationLevel,
          name: String,
          tags: [String] = [],
          problemSetDescription: String? = nil,
          isFavorite: Bool = false
      ) {
          self.id = id
          self.title = title
          self.subject = subject
          self.difficulty = difficulty
          self.questions = questions
          self.createdAt = createdAt
          self.lastAttempted = lastAttempted
          self.educationLevel = educationLevel
          self.name = name
          self.tags = tags
          self.problemSetDescription = problemSetDescription
          self.isFavorite = isFavorite
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
