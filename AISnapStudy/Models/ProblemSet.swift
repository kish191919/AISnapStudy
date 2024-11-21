import Foundation

public struct ProblemSet: Identifiable, Codable, Hashable {
   public let id: String
   public let subject: DefaultSubject  // Subject를 DefaultSubject로 변경
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
   
   public init(
       id: String,
       subject: DefaultSubject,  // Subject를 DefaultSubject로 변경
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
       self.subject = subject
       self.questions = questions
       self.createdAt = createdAt
       self.lastAttempted = lastAttempted
       self.educationLevel = educationLevel
       self.name = name
       self.tags = tags
       self.problemSetDescription = problemSetDescription
       self.isFavorite = isFavorite
   }
   
   // CodingKeys 추가
   private enum CodingKeys: String, CodingKey {
       case id
       case subject
       case questions
       case createdAt
       case lastAttempted
       case educationLevel
       case name
       case tags
       case problemSetDescription
       case isFavorite
   }
   
   // Decodable 구현
   public init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       
       id = try container.decode(String.self, forKey: .id)
       subject = try container.decode(DefaultSubject.self, forKey: .subject)
       questions = try container.decode([Question].self, forKey: .questions)
       createdAt = try container.decode(Date.self, forKey: .createdAt)
       lastAttempted = try container.decodeIfPresent(Date.self, forKey: .lastAttempted)
       educationLevel = try container.decode(EducationLevel.self, forKey: .educationLevel)
       name = try container.decode(String.self, forKey: .name)
       tags = try container.decode([String].self, forKey: .tags)
       problemSetDescription = try container.decodeIfPresent(String.self, forKey: .problemSetDescription)
       isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
   }
   
   // Encodable 구현
   public func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)
       
       try container.encode(id, forKey: .id)
       try container.encode(subject, forKey: .subject)
       try container.encode(questions, forKey: .questions)
       try container.encode(createdAt, forKey: .createdAt)
       try container.encodeIfPresent(lastAttempted, forKey: .lastAttempted)
       try container.encode(educationLevel, forKey: .educationLevel)
       try container.encode(name, forKey: .name)
       try container.encode(tags, forKey: .tags)
       try container.encodeIfPresent(problemSetDescription, forKey: .problemSetDescription)
       try container.encode(isFavorite, forKey: .isFavorite)
   }
   
   // Hashable 구현
   public func hash(into hasher: inout Hasher) {
       hasher.combine(id)
   }
   
   public static func == (lhs: ProblemSet, rhs: ProblemSet) -> Bool {
       lhs.id == rhs.id
   }
}
