// CoreData/CoreDataService.swift

import CoreData
import Foundation

class CoreDataService {
    static let shared = CoreDataService()
    
    private let containerName = "AISnapStudy"
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreData store failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {}
    
    func saveProblemSet(_ problemSet: ProblemSet) throws {
        let cdProblemSet = CDProblemSet(context: context)
        updateCDProblemSet(cdProblemSet, with: problemSet)
        try context.save()
    }
    
    private func updateCDProblemSet(_ cdProblemSet: CDProblemSet, with problemSet: ProblemSet) {
        cdProblemSet.id = problemSet.id
        cdProblemSet.title = problemSet.title
        cdProblemSet.subject = problemSet.subject.rawValue
        cdProblemSet.difficulty = problemSet.difficulty.rawValue
        cdProblemSet.createdAt = problemSet.createdAt
        cdProblemSet.lastAttempted = problemSet.lastAttempted
        
        problemSet.questions.forEach { question in
            let cdQuestion = CDQuestion(context: context)
            cdQuestion.id = question.id
            cdQuestion.type = question.type.rawValue
            cdQuestion.question = question.question
            cdQuestion.options = question.options as NSObject
            cdQuestion.matchingOptions = question.matchingOptions as NSObject
            cdQuestion.correctAnswer = question.correctAnswer
            cdQuestion.explanation = question.explanation
            cdQuestion.hint = question.hint
            cdQuestion.isSaved = question.isSaved
            cdQuestion.createdAt = question.createdAt
            cdQuestion.problemSet = cdProblemSet
        }
    }
    
    func fetchProblemSets() throws -> [ProblemSet] {
        let request: NSFetchRequest<CDProblemSet> = CDProblemSet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let cdProblemSets = try context.fetch(request)
        return cdProblemSets.map { $0.toDomain() }
    }
    
    func saveStudySession(_ session: StudySession) throws {
        let cdSession = CDStudySession(context: context)
        cdSession.id = session.id
        cdSession.startTime = session.startTime
        cdSession.endTime = session.endTime
        cdSession.answers = session.answers as NSObject
        cdSession.score = Int16(session.score ?? 0)
        
        if let cdProblemSet = try? fetchCDProblemSet(withID: session.problemSet.id) {
            cdSession.problemSet = cdProblemSet
        }
        
        try context.save()
    }
    
    private func fetchCDProblemSet(withID id: String) throws -> CDProblemSet? {
        let request: NSFetchRequest<CDProblemSet> = CDProblemSet.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try context.fetch(request).first
    }
    
    func clearAllData() throws {
        let entityNames = ["CDProblemSet", "CDQuestion", "CDStudySession"]
        try entityNames.forEach { entityName in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: context)
        }
        try context.save()
    }
}
