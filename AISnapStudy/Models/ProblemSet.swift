import Foundation

public struct ProblemSet: Identifiable, Codable, Hashable {
    // Core properties
    public let id: String
    public let subject: DefaultSubject  // 필수 프로퍼티로 유지
    public let subjectType: String
    public let subjectId: String
    public let subjectName: String
    public let questions: [Question]
    public let createdAt: Date
    public var lastAttempted: Date?
    public let educationLevel: EducationLevel
    public var name: String
    public var tags: [String]
    public var problemSetDescription: String?
    public var isFavorite: Bool

    public var questionCount: Int {
        questions.count
    }

    public var resolvedSubject: SubjectType {
        if subjectType == "default" {
            return DefaultSubject(rawValue: subjectId) ?? .generalKnowledge
        } else {
            return SubjectManager.shared.customSubjects.first(where: { $0.id == subjectId }) ?? DefaultSubject.generalKnowledge
        }
    }

    // CustomSubject를 위한 생성자
    public init(
        id: String = UUID().uuidString,
        subject: DefaultSubject,
        subjectType: String,
        subjectId: String,
        subjectName: String,
        questions: [Question],
        createdAt: Date = Date(),
        educationLevel: EducationLevel,
        name: String
    ) {
        self.id = id
        self.subject = subject
        self.subjectType = subjectType
        self.subjectId = subjectId
        self.subjectName = subjectName
        self.questions = questions
        self.createdAt = createdAt
        self.educationLevel = educationLevel
        self.name = name
        self.tags = []
        self.problemSetDescription = nil
        self.isFavorite = false
    }

    private enum CodingKeys: String, CodingKey {
        case id, subject, subjectType, subjectId, subjectName
        case questions, createdAt, lastAttempted
        case educationLevel, name, tags
        case problemSetDescription, isFavorite
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        subject = try container.decode(DefaultSubject.self, forKey: .subject)
        subjectType = try container.decode(String.self, forKey: .subjectType)
        subjectId = try container.decode(String.self, forKey: .subjectId)
        subjectName = try container.decode(String.self, forKey: .subjectName)
        questions = try container.decode([Question].self, forKey: .questions)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastAttempted = try container.decodeIfPresent(Date.self, forKey: .lastAttempted)
        educationLevel = try container.decode(EducationLevel.self, forKey: .educationLevel)
        name = try container.decode(String.self, forKey: .name)
        tags = try container.decode([String].self, forKey: .tags)
        problemSetDescription = try container.decodeIfPresent(String.self, forKey: .problemSetDescription)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(subject, forKey: .subject)
        try container.encode(subjectType, forKey: .subjectType)
        try container.encode(subjectId, forKey: .subjectId)
        try container.encode(subjectName, forKey: .subjectName)
        try container.encode(questions, forKey: .questions)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastAttempted, forKey: .lastAttempted)
        try container.encode(educationLevel, forKey: .educationLevel)
        try container.encode(name, forKey: .name)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(problemSetDescription, forKey: .problemSetDescription)
        try container.encode(isFavorite, forKey: .isFavorite)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ProblemSet, rhs: ProblemSet) -> Bool {
        lhs.id == rhs.id
    }
}
