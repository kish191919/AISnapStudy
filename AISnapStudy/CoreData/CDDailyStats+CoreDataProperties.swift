

import Foundation
import CoreData


extension CDDailyStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDailyStats> {
        return NSFetchRequest<CDDailyStats>(entityName: "CDDailyStats")
    }

    @NSManaged public var date: Date?
    @NSManaged public var totalQuestions: Int32
    @NSManaged public var correctAnswers: Int32

}

extension CDDailyStats : Identifiable {

}
