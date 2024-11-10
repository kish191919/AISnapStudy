// Models/StudySession.swift
import Foundation

public struct StudySession: Identifiable, Codable {
    public let id: String
    public let problemSet: ProblemSet
    public let startTime: Date
    public var endTime: Date?
    public var answers: [String: String] // [QuestionId: UserAnswer]
    public var score: Int?
    
    public var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    public init(
        id: String = UUID().uuidString,
        problemSet: ProblemSet,
        startTime: Date = Date(),
        endTime: Date? = nil,
        answers: [String: String] = [:],
        score: Int? = nil
    ) {
        self.id = id
        self.problemSet = problemSet
        self.startTime = startTime
        self.endTime = endTime
        self.answers = answers
        self.score = score
    }
}

// MARK: - Computed Properties
extension StudySession {
    public var isCompleted: Bool {
        endTime != nil
    }
    
    public var isSaved: Bool {
        // 실제 구현에서는 저장 상태를 확인하는 로직 추가
        false
    }
    
    public var correctAnswers: [String: String] {
        var answers: [String: String] = [:]
        for question in problemSet.questions {
            answers[question.id] = question.correctAnswer
        }
        return answers
    }
}

// MARK: - Hashable
extension StudySession: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: StudySession, rhs: StudySession) -> Bool {
        lhs.id == rhs.id
    }
}
