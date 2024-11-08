//
//  CDQuestion+CoreDataProperties.swift
//  AISnapStudy
//
//  Created by sunghwan ki on 11/8/24.
//
//

import Foundation
import CoreData


extension CDQuestion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDQuestion> {
        return NSFetchRequest<CDQuestion>(entityName: "CDQuestion")
    }

    @NSManaged public var id: String?
    @NSManaged public var type: String?
    @NSManaged public var question: String?
    @NSManaged public var options: NSObject?
    @NSManaged public var matchingOptions: NSObject?
    @NSManaged public var correctAnswer: String?
    @NSManaged public var explanation: String?
    @NSManaged public var hint: String?
    @NSManaged public var isSaved: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var problemSet: CDProblemSet?

}

extension CDQuestion : Identifiable {

}
