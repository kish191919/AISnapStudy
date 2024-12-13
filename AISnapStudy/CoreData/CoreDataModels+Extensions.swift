

import Foundation
import CoreData

// MARK: - CDProblemSet Extension
extension CDProblemSet {
    func toDomain() -> ProblemSet {
        let questions = (self.questions?.allObjects as? [CDQuestion])?.compactMap { question -> Question? in
            question.toDomain()
        } ?? []

        let defaultSubject = DefaultSubject(rawValue: self.subject ?? "") ?? .generalKnowledge

        return ProblemSet(
            id: self.id ?? UUID().uuidString,
            subject: defaultSubject,
            subjectType: self.subjectType ?? "default",
            subjectId: self.subjectId ?? defaultSubject.rawValue,
            subjectName: self.subjectName ?? defaultSubject.displayName,
            questions: questions,
            createdAt: self.createdAt ?? Date(),
            educationLevel: EducationLevel(rawValue: self.educationLevel ?? "") ?? .elementary,
            name: self.name ?? ""
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
            subject: DefaultSubject(rawValue: self.problemSet?.subject ?? "") ?? .generalKnowledge,
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
        let defaultSubject = DefaultSubject.generalKnowledge
        
        return StudySession(
            id: self.id ?? UUID().uuidString,
            problemSet: self.problemSet?.toDomain() ?? ProblemSet(
                id: UUID().uuidString,
                subject: defaultSubject,
                subjectType: "default",
                subjectId: defaultSubject.rawValue,
                subjectName: defaultSubject.displayName,
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
