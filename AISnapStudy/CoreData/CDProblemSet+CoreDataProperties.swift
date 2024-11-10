// File: CoreData/CDProblemSet+CoreDataProperties.swift

import Foundation
import CoreData

extension CDProblemSet {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDProblemSet> {
        return NSFetchRequest<CDProblemSet>(entityName: "CDProblemSet")
    }

    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var subject: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastAttempted: Date?
    @NSManaged public var questions: NSSet?
}

// MARK: Generated accessors for questions
extension CDProblemSet {
    @objc(addQuestionsObject:)
    @NSManaged public func addToQuestions(_ value: CDQuestion)

    @objc(removeQuestionsObject:)
    @NSManaged public func removeFromQuestions(_ value: CDQuestion)

    @objc(addQuestions:)
    @NSManaged public func addToQuestions(_ values: NSSet)

    @objc(removeQuestions:)
    @NSManaged public func removeFromQuestions(_ values: NSSet)
}
