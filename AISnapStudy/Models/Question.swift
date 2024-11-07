// Models/Question.swift
import Foundation
import Foundation

public enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case fillInBlanks = "fill_in_blanks"
    case matching = "matching"
}

public struct Question: Identifiable, Codable {
    public let id: String
    public let type: QuestionType
    public let subject: Subject
    public let difficulty: Difficulty
    public let question: String
    public let options: [String]
    public let matchingOptions: [String]
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
        matchingOptions: [String] = [],
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
        self.matchingOptions = matchingOptions
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.hint = hint
        self.isSaved = isSaved
        self.createdAt = createdAt
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
