import CoreData
import Foundation

class CoreDataService {
    static let shared = CoreDataService()
    
    // private -> public으로 변경
    public var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AISnapStudy")
        
        // 저장소 설명 생성
        let storeDescription = NSPersistentStoreDescription()
        
        // Application Support 디렉토리 생성 확인
        if let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            // Application Support 디렉토리가 없다면 생성
            if !FileManager.default.fileExists(atPath: applicationSupportURL.path) {
                do {
                    try FileManager.default.createDirectory(
                        at: applicationSupportURL,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    print("✅ Created Application Support directory")
                } catch {
                    print("❌ Failed to create Application Support directory: \(error)")
                }
            }
            
            // 데이터베이스 파일 URL 설정
            let storeURL = applicationSupportURL.appendingPathComponent("AISnapStudy.sqlite")
            storeDescription.url = storeURL
            
            print("📁 CoreData store URL: \(storeURL.path)")
            
            // 마이그레이션 옵션 설정
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            storeDescription.setOption(["journal_mode": "WAL"] as NSDictionary, forKey: NSSQLitePragmasOption)
            storeDescription.setOption(FileProtectionType.complete as NSString, forKey: NSPersistentStoreFileProtectionKey)
            
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        // 저장소 로드
        container.loadPersistentStores { description, error in
            if let error = error {
                print("""
                ❌ CoreData Error:
                • Error: \(error.localizedDescription)
                • Description: \(description)
                • Store URL: \(description.url?.absoluteString ?? "unknown")
                """)
                
                // 오류 발생 시 저장소 재생성 시도
                if let storeURL = description.url {
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        print("🔄 Removed existing store file")
                        
                        // 저장소 재생성
                        try container.persistentStoreCoordinator.addPersistentStore(
                            ofType: NSSQLiteStoreType,
                            configurationName: nil,
                            at: storeURL,
                            options: [
                                NSMigratePersistentStoresAutomaticallyOption: true,
                                NSInferMappingModelAutomaticallyOption: true
                            ]
                        )
                        print("✅ Successfully recreated store")
                    } catch {
                        print("❌ Failed to recreate store: \(error)")
                        fatalError("Unresolved error \(error)")
                    }
                }
            } else {
                print("✅ CoreData store loaded successfully")
            }
        }
        
        // Context 설정
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    // MARK: - Question Operations 섹션에 추가
    // MARK: - Question Operations
    public func fetchSavedQuestions() throws -> [Question] {
        print("📊 Fetching Saved Questions from CoreData")
        let request: NSFetchRequest<CDQuestion> = CDQuestion.fetchRequest()
        request.predicate = NSPredicate(format: "isSaved == true")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let cdQuestions = try viewContext.fetch(request)
            print("📊 Found \(cdQuestions.count) saved questions")
            
            let questions = cdQuestions.compactMap { cdQuestion -> Question? in
                guard let id = cdQuestion.id,
                      let type = cdQuestion.type,
                      let questionText = cdQuestion.question,
                      let correctAnswer = cdQuestion.correctAnswer,
                      let explanation = cdQuestion.explanation else {
                    print("⚠️ Invalid question data found")
                    return nil
                }
                
                let options = cdQuestion.options as? [String] ?? []
                
                return Question(
                    id: id,
                    type: QuestionType(rawValue: type) ?? .multipleChoice,
                    subject: DefaultSubject(rawValue: cdQuestion.problemSet?.subject ?? "") ?? .math,
                    question: questionText,
                    options: options,
                    correctAnswer: correctAnswer,
                    explanation: explanation,
                    hint: cdQuestion.hint,
                    isSaved: cdQuestion.isSaved,
                    createdAt: cdQuestion.createdAt ?? Date()
                )
            }
            
            print("✅ Successfully mapped \(questions.count) saved questions")
            return questions
            
        } catch {
            print("❌ Failed to fetch saved questions: \(error)")
            throw error
        }
    }

    // 기존 saveQuestion 메서드 수정
    public func saveQuestion(_ question: Question) throws {
        print("💾 Attempting to save question: \(question.id)")
        
        // 먼저 이미 존재하는지 확인
        let request: NSFetchRequest<CDQuestion> = CDQuestion.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", question.id)
        
        do {
            let existingQuestions = try viewContext.fetch(request)
            let cdQuestion: CDQuestion
            
            if let existingQuestion = existingQuestions.first {
                print("📝 Updating existing question")
                cdQuestion = existingQuestion
            } else {
                print("📝 Creating new question")
                cdQuestion = CDQuestion(context: viewContext)
            }
            
            // 질문 데이터 업데이트
            updateCDQuestion(cdQuestion, with: question)
            
            try viewContext.save()
            print("✅ Successfully saved question: \(question.id)")
            
        } catch {
            print("❌ Failed to save question: \(error)")
            viewContext.rollback()
            throw error
        }
    }
    
    // viewContext에 대한 public 접근자 추가
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {}
    
    // 공개 메서드들...
    public func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                print("✅ CoreData context saved successfully")
            } catch {
                print("❌ CoreData context save error: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - ProblemSet Operations
    // File: ./AISnapStudy/CoreData/CoreDataService.swift

    public func fetchProblemSets() throws -> [ProblemSet] {
        print("📊 Fetching ProblemSets from CoreData")
        let request: NSFetchRequest<CDProblemSet> = CDProblemSet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let cdProblemSets = try viewContext.fetch(request)
            print("📊 Fetched \(cdProblemSets.count) ProblemSets from CoreData")
            
            return try cdProblemSets.map { cdProblemSet -> ProblemSet in
                let questions = (cdProblemSet.questions?.allObjects as? [CDQuestion])?
                    .compactMap { cdQuestion -> Question? in
                        guard let id = cdQuestion.id,
                              let type = cdQuestion.type,
                              let questionText = cdQuestion.question,
                              let correctAnswer = cdQuestion.correctAnswer,
                              let explanation = cdQuestion.explanation else {
                            print("⚠️ Invalid question data found")
                            return nil
                        }
                        
                        let options = cdQuestion.options as? [String] ?? []
                        
                        return Question(
                            id: id,
                            type: QuestionType(rawValue: type) ?? .multipleChoice,
                            subject: DefaultSubject(rawValue: cdProblemSet.subject ?? "") ?? .math,
                            question: questionText,
                            options: options,
                            correctAnswer: correctAnswer,
                            explanation: explanation,
                            hint: cdQuestion.hint,
                            isSaved: cdQuestion.isSaved,
                            createdAt: cdQuestion.createdAt ?? Date()
                        )
                    } ?? []
                
                let defaultSubject = DefaultSubject(rawValue: cdProblemSet.subject ?? "") ?? .math
                
                return ProblemSet(
                    id: cdProblemSet.id ?? UUID().uuidString,
                    subject: defaultSubject,
                    subjectType: cdProblemSet.subjectType ?? "default",
                    subjectId: cdProblemSet.subjectId ?? defaultSubject.rawValue,
                    subjectName: cdProblemSet.subjectName ?? defaultSubject.displayName,
                    questions: questions,
                    createdAt: cdProblemSet.createdAt ?? Date(),
                    educationLevel: EducationLevel(rawValue: cdProblemSet.educationLevel ?? "") ?? .elementary,
                    name: cdProblemSet.name ?? "Default Name"
                )
            }
        } catch {
            print("❌ Failed to fetch ProblemSets: \(error)")
            throw error
        }
    }
    public func saveProblemSet(_ problemSet: ProblemSet) throws {
        print("📝 Starting to save ProblemSet: \(problemSet.id)")
        
        let context = persistentContainer.viewContext
        let cdProblemSet = CDProblemSet(context: context)
        
        cdProblemSet.id = problemSet.id
        
        // subject 저장 로직 수정
        if let defaultSubject = problemSet.subject as? DefaultSubject {
            cdProblemSet.subject = defaultSubject.rawValue
        } else if let customSubject = problemSet.subject as? CustomSubject {
            cdProblemSet.subject = customSubject.id  // CustomSubject의 경우 id 사용
            cdProblemSet.subjectType = "custom"
            cdProblemSet.subjectName = customSubject.name
        } else {
            cdProblemSet.subject = DefaultSubject.generalKnowledge.rawValue
        }
        
        cdProblemSet.subjectType = problemSet.subjectType
        cdProblemSet.subjectId = problemSet.subjectId
        cdProblemSet.subjectName = problemSet.subjectName
        cdProblemSet.name = problemSet.name  // Ensure name is saved
        
        cdProblemSet.createdAt = problemSet.createdAt
        cdProblemSet.lastAttempted = problemSet.lastAttempted
        
        // 문제 저장 전 로그
        print("💾 Preparing to save \(problemSet.questions.count) questions")
        
        // questions 관계 설정
        let questionSet = NSMutableSet()
        
        for question in problemSet.questions {
            let cdQuestion = CDQuestion(context: viewContext)
            cdQuestion.id = question.id
            cdQuestion.type = question.type.rawValue
            cdQuestion.question = question.question
            
            // options 배열 변환 및 저장
            cdQuestion.options = NSArray(array: question.options)
            
            cdQuestion.correctAnswer = question.correctAnswer
            cdQuestion.explanation = question.explanation
            cdQuestion.hint = question.hint
            cdQuestion.isSaved = question.isSaved
            cdQuestion.createdAt = question.createdAt
            cdQuestion.problemSet = cdProblemSet
            
            questionSet.add(cdQuestion)
            
            print("✏️ Prepared question: \(question.id)")
        }
        
        cdProblemSet.questions = questionSet
        
        do {
            try viewContext.save()
            print("✅ Successfully saved ProblemSet with \(questionSet.count) questions")
            
            // 저장 후 확인
            if let savedQuestions = cdProblemSet.questions {
                print("📚 Verified \(savedQuestions.count) questions in CoreData")
            }
        } catch {
            print("❌ Failed to save ProblemSet: \(error)")
            viewContext.rollback()
            throw error
        }
    }
    
    public func deleteQuestion(_ question: Question) throws {
        // Type annotation을 명시적으로 지정
        let request = NSFetchRequest<CDQuestion>(entityName: "CDQuestion")
        // 또는 아래와 같이 작성 가능
        // let request: NSFetchRequest<CDQuestion> = NSFetchRequest(entityName: "CDQuestion")
        
        request.predicate = NSPredicate(format: "id == %@", question.id)
        
        do {
            let questions = try viewContext.fetch(request)
            if let cdQuestion = questions.first {
                viewContext.delete(cdQuestion)
                try viewContext.save()
                print("✅ Deleted Question: \(question.id)")
            }
        } catch {
            print("❌ Failed to delete Question: \(error)")
            viewContext.rollback()
            throw error
        }
    }
    
    // MARK: - Helper Methods
    // 조회 로직도 수정
    private func updateCDQuestion(_ cdQuestion: CDQuestion, with question: Question) {
        cdQuestion.id = question.id
        cdQuestion.type = question.type.rawValue
        cdQuestion.question = question.question
        
        // Convert String arrays to NSArray
        cdQuestion.options = NSArray(array: question.options)
        cdQuestion.correctAnswer = question.correctAnswer
        cdQuestion.explanation = question.explanation
        cdQuestion.hint = question.hint
        cdQuestion.isSaved = question.isSaved
        cdQuestion.createdAt = question.createdAt
    }
}

// CDQuestion+Extension 수정
extension CDQuestion {
    func toDomain() -> Question? {
        guard let id = self.id,
              let type = self.type,
              let question = self.question,
              let correctAnswer = self.correctAnswer,
              let explanation = self.explanation else {
            return nil
        }
        
        let options = (self.options as? [String]) ?? []
        
        return Question(
            id: id,
            type: QuestionType(rawValue: type) ?? .multipleChoice,
            subject: DefaultSubject(rawValue: self.problemSet?.subject ?? "") ?? .math,
            question: question,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanation,
            hint: self.hint,
            isSaved: self.isSaved,
            createdAt: self.createdAt ?? Date()
        )
    }
}
extension CoreDataService {
    @MainActor
    func updateProblemSet(_ problemSet: ProblemSet, newName: String) throws {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<CDProblemSet> = CDProblemSet.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", problemSet.id)
        
        if let cdProblemSet = try context.fetch(request).first {
            cdProblemSet.name = newName
            
            // Save immediately
            if context.hasChanges {
                try context.save()
                print("💾 CoreData: Successfully updated problem set name to: \(newName)")
            }
        } else {
            print("⚠️ CoreData: Problem set not found with ID: \(problemSet.id)")
        }
    }
    
    func deleteProblemSet(_ problemSet: ProblemSet) throws {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<CDProblemSet> = CDProblemSet.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", problemSet.id)
        
        if let cdProblemSet = try context.fetch(request).first {
            context.delete(cdProblemSet)
            try context.save()
        }
    }
}

extension CoreDataService {
    func saveDailyStats(_ stats: DailyStats) throws {
        let context = viewContext
        let today = Calendar.current.startOfDay(for: Date())
        
        let fetchRequest: NSFetchRequest<CDDailyStats> = CDDailyStats.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
            today as NSDate,
            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate
        )
        
        do {
            let existingStats = try context.fetch(fetchRequest)
            let dailyStats: CDDailyStats
            
            if let existing = existingStats.first {
                print("📊 Found existing stats - Questions: \(existing.totalQuestions), Correct: \(existing.correctAnswers)")
                dailyStats = existing
                // 누적 처리
                dailyStats.totalQuestions += 1  // 항상 1씩 증가
                if stats.correctAnswers > existing.correctAnswers {
                    dailyStats.correctAnswers += 1
                }
            } else {
                print("📊 Creating new daily stats")
                dailyStats = CDDailyStats(context: context)
                dailyStats.date = today
                dailyStats.totalQuestions = 1
                dailyStats.correctAnswers = Int32(stats.correctAnswers)
            }
            
            try context.save()
            
            print("""
            ✅ Daily stats saved:
            • Date: \(today)
            • Previous Total: \(existingStats.first?.totalQuestions ?? 0)
            • New Total: \(dailyStats.totalQuestions)
            • Previous Correct: \(existingStats.first?.correctAnswers ?? 0)
            • New Correct: \(dailyStats.correctAnswers)
            """)
            
        } catch {
            print("❌ Failed to save daily stats: \(error)")
            throw error
        }
    }

    func fetchDailyStats(for date: Date = Date()) throws -> DailyStats? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<CDDailyStats> = CDDailyStats.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            if let stats = try viewContext.fetch(fetchRequest).first {
                return DailyStats(
                    id: UUID(),
                    date: startOfDay,
                    totalQuestions: Int(stats.totalQuestions),
                    correctAnswers: Int(stats.correctAnswers),
                    wrongAnswers: Int(stats.totalQuestions - stats.correctAnswers),
                    timeSpent: 0
                )
            }
            return nil
        } catch {
            print("❌ Failed to fetch daily stats: \(error)")
            throw error
        }
    }
}
