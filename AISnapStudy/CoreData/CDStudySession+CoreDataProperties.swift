//
//  CDStudySession+CoreDataProperties.swift
//  AISnapStudy
//
//  Created by sunghwan ki on 11/8/24.
//
//

import Foundation
import CoreData


extension CDStudySession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStudySession> {
        return NSFetchRequest<CDStudySession>(entityName: "CDStudySession")
    }

    @NSManaged public var id: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var answers: NSObject?
    @NSManaged public var score: Int16
    @NSManaged public var problemSet: CDProblemSet?

}

extension CDStudySession : Identifiable {

}
