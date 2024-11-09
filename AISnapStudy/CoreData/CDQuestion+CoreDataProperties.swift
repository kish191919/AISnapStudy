// File: ./AISnapStudy/CoreData/CDQuestion+CoreDataProperties.swift

import Foundation
import CoreData

extension CDQuestion {
    @NSManaged public var id: String?
    @NSManaged public var type: String?
    @NSManaged public var question: String?
    @NSManaged public var options: NSArray?         // NSObject 대신 NSArray 사용
    @NSManaged public var matchingOptions: NSArray? // NSObject 대신 NSArray 사용
    @NSManaged public var correctAnswer: String?
    @NSManaged public var explanation: String?
    @NSManaged public var hint: String?
    @NSManaged public var isSaved: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var problemSet: CDProblemSet?
}
