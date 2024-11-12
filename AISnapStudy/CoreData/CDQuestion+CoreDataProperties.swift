

import Foundation
import CoreData


extension CDQuestion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDQuestion> {
        return NSFetchRequest<CDQuestion>(entityName: "CDQuestion")
    }

    @NSManaged public var attribute: String?
    @NSManaged public var correctAnswer: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var explanation: String?
    @NSManaged public var hint: String?
    @NSManaged public var id: String?
    @NSManaged public var isCorrect: Bool
    @NSManaged public var isSaved: Bool
    @NSManaged public var options: NSObject?
    @NSManaged public var question: String?
    @NSManaged public var type: String?
    @NSManaged public var problemSet: CDProblemSet?
    @NSManaged public var session: CDStudySession?

}

extension CDQuestion : Identifiable {

}
