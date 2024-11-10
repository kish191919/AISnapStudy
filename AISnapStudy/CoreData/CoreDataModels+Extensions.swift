

import Foundation
import CoreData

// MARK: - CDProblemSet Extension
extension CDProblemSet {
    func toDomain() -> ProblemSet {
        let questions = (self.questions?.allObjects as? [CDQuestion])?.compactMap { question -> Question? in
            question.toDomain()
        } ?? []

        return ProblemSet(
            id: self.id ?? UUID().uuidString,
            title: self.title ?? "",
            subject: Subject(rawValue: self.subject ?? "") ?? .math,
            difficulty: Difficulty(rawValue: self.difficulty ?? "") ?? .medium,
            questions: questions,
            createdAt: self.createdAt ?? Date(),
            lastAttempted: self.lastAttempted
        )
    }
}

// MARK: - CDQuestion Extension
extension CDQuestion {
    func toDomain() -> Question {
        Question(
            id: self.id ?? UUID().uuidString,
            type: QuestionType(rawValue: self.type ?? "") ?? .multipleChoice,
            subject: Subject(rawValue: self.problemSet?.subject ?? "") ?? .math,
            difficulty: Difficulty(rawValue: self.problemSet?.difficulty ?? "") ?? .medium,
            question: self.question ?? "",
            options: self.options as? [String] ?? [],
            matchingOptions: self.matchingOptions as? [String] ?? [],
            correctAnswer: self.correctAnswer ?? "",
            explanation: self.explanation ?? "",
            hint: self.hint,
            isSaved: self.isSaved,
            createdAt: self.createdAt ?? Date()
        )
    }
}

// MARK: - CDStudySession Extension
extension CDStudySession {
    func toDomain() -> StudySession {
        StudySession(
            id: self.id ?? UUID().uuidString,
            problemSet: self.problemSet?.toDomain() ?? ProblemSet(
                id: UUID().uuidString,
                title: "Unknown",
                subject: .math,
                difficulty: .medium,
                questions: [],
                createdAt: Date()
            ),
            startTime: self.startTime ?? Date(),
            endTime: self.endTime,
            answers: self.answers as? [String: String] ?? [:],
            score: Int(self.score)
        )
    }
}
