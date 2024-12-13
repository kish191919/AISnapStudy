

import Foundation

public enum QuestionType: String, Codable {
   case multipleChoice = "multiple_choice"
   case trueFalse = "true_false"
}

public struct Question: Identifiable, Codable, Hashable {
   public let id: String
   public let type: QuestionType
   public let subject: DefaultSubject  // Subject를 DefaultSubject로 변경
   public let question: String
   public let options: [String]
   public let correctAnswer: String
   public let explanation: String
   public let hint: String?
   public var isSaved: Bool
   public let createdAt: Date
   
   private enum CodingKeys: String, CodingKey {
       case id, type, subject, question, options
       case correctAnswer, explanation, hint
       case isSaved, createdAt
   }
   
   public init(
       id: String,
       type: QuestionType,
       subject: DefaultSubject,  // Subject를 DefaultSubject로 변경
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
       self.question = question
       self.options = options
       self.correctAnswer = correctAnswer
       self.explanation = explanation
       self.hint = hint
       self.isSaved = isSaved
       self.createdAt = createdAt
   }
   
   // Decodable 구현
   public init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       
       id = try container.decode(String.self, forKey: .id)
       type = try container.decode(QuestionType.self, forKey: .type)
       subject = try container.decode(DefaultSubject.self, forKey: .subject)
       question = try container.decode(String.self, forKey: .question)
       options = try container.decode([String].self, forKey: .options)
       correctAnswer = try container.decode(String.self, forKey: .correctAnswer)
       explanation = try container.decode(String.self, forKey: .explanation)
       hint = try container.decodeIfPresent(String.self, forKey: .hint)
       isSaved = try container.decode(Bool.self, forKey: .isSaved)
       createdAt = try container.decode(Date.self, forKey: .createdAt)
   }
    // Hashable 프로토콜 요구사항을 여기에 직접 구현
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Question, rhs: Question) -> Bool {
        lhs.id == rhs.id
    }
   
   // Encodable 구현
   public func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)
       
       try container.encode(id, forKey: .id)
       try container.encode(type, forKey: .type)
       try container.encode(subject, forKey: .subject)
       try container.encode(question, forKey: .question)
       try container.encode(options, forKey: .options)
       try container.encode(correctAnswer, forKey: .correctAnswer)
       try container.encode(explanation, forKey: .explanation)
       try container.encodeIfPresent(hint, forKey: .hint)
       try container.encode(isSaved, forKey: .isSaved)
       try container.encode(createdAt, forKey: .createdAt)
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
           subject: DefaultSubject(rawValue: subjectRaw) ?? .generalKnowledge,  // Subject를 DefaultSubject로 변경
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

extension Question {
    var processedCorrectAnswer: String {
        switch type {
        case .trueFalse:
            return correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        case .multipleChoice:
            return correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
