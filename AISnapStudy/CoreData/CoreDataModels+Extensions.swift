

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
            // Subject를 DefaultSubject로 변경
            subject: DefaultSubject(rawValue: self.subject ?? "") ?? .math,
            questions: questions,
            createdAt: self.createdAt ?? Date(),
            lastAttempted: self.lastAttempted,
            educationLevel: EducationLevel(rawValue: self.educationLevel ?? "") ?? .elementary,
            name: self.name ?? "",
            tags: self.tags as? [String] ?? [],
            problemSetDescription: self.problemSetDescription,
            isFavorite: self.isFavorite
        )
    }
}

// MARK: - CDQuestion Extension
extension CDQuestion {
    func toDomain() -> Question {
        Question(
            id: self.id ?? UUID().uuidString,
            type: QuestionType(rawValue: self.type ?? "") ?? .multipleChoice,
            // Subject를 DefaultSubject로 변경
            subject: DefaultSubject(rawValue: self.problemSet?.subject ?? "") ?? .math,
            question: self.question ?? "",
            options: self.options as? [String] ?? [],
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
                // Subject를 DefaultSubject로 변경
                subject: .math,  // DefaultSubject.math
                questions: [],
                createdAt: Date(),
                educationLevel: .elementary,
                name: "Default Name"
            ),
            startTime: self.startTime ?? Date(),
            endTime: self.endTime,
            answers: self.answers as? [String: String] ?? [:],
            score: Int(self.score)
        )
    }
}
