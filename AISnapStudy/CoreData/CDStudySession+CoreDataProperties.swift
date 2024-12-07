

import Foundation
import CoreData


extension CDStudySession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStudySession> {
        return NSFetchRequest<CDStudySession>(entityName: "CDStudySession")
    }

    @NSManaged public var answers: NSObject?
    @NSManaged public var endTime: Date?
    @NSManaged public var id: String?
    @NSManaged public var score: Int16
    @NSManaged public var startTime: Date?
    @NSManaged public var problemSet: CDProblemSet?
    @NSManaged public var questions: NSSet?

}

// MARK: Generated accessors for questions
extension CDStudySession {

    @objc(addQuestionsObject:)
    @NSManaged public func addToQuestions(_ value: CDQuestion)

    @objc(removeQuestionsObject:)
    @NSManaged public func removeFromQuestions(_ value: CDQuestion)

    @objc(addQuestions:)
    @NSManaged public func addToQuestions(_ values: NSSet)

    @objc(removeQuestions:)
    @NSManaged public func removeFromQuestions(_ values: NSSet)

}

extension CDStudySession : Identifiable {

}
