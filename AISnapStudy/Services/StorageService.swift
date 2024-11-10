
import Foundation

public enum StorageError: Error {
    case saveFailed
    case loadFailed
    case deleteFailed
    case notFound
    case invalidData
}

public class StorageService {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private let problemSetsKey = "problemSets"
    private let savedQuestionsKey = "savedQuestions"
    private let studySessionsKey = "studySessions"
    
    private let fileManager = FileManager.default
     
     private var documentDirectory: URL? {
         fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
     }
     
     private func getDirectoryURL(for type: String) -> URL? {
         documentDirectory?.appendingPathComponent(type)
     }
     
     private func handleFileOperation<T>(_ operation: () throws -> T) throws -> T {
         do {
             return try operation()
         } catch let error as NSError {
             print("""
             ❌ File Operation Error:
             • Error Domain: \(error.domain)
             • Error Code: \(error.code)
             • Description: \(error.localizedDescription)
             """)
             
             // 재시도 로직
             let retryCount = 3
             for attempt in 1...retryCount {
                 print("🔄 Retrying operation (attempt \(attempt)/\(retryCount))")
                 do {
                     return try operation()
                 } catch {
                     if attempt == retryCount {
                         throw error
                     }
                     Thread.sleep(forTimeInterval: 0.5)
                 }
             }
             throw error
         }
     }
    
    // MARK: - Problem Sets
    public func saveProblemSet(_ problemSet: ProblemSet) throws {
        try handleFileOperation {
            var problemSets = try getProblemSets()
            problemSets.append(problemSet)
            
            let data = try encoder.encode(problemSets)
            defaults.set(data, forKey: problemSetsKey)
        }
    }
        
    
    public func getProblemSets() throws -> [ProblemSet] {
        guard let data = defaults.data(forKey: problemSetsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([ProblemSet].self, from: data)
        } catch {
            throw StorageError.loadFailed
        }
    }
    
    // MARK: - Study Sessions
    public func saveStudySession(_ session: StudySession) throws {
        var sessions = try getStudySessions()
        sessions.append(session)
        
        do {
            let data = try encoder.encode(sessions)
            defaults.set(data, forKey: studySessionsKey)
        } catch {
            throw StorageError.saveFailed
        }
    }
    
    public func getStudySessions() throws -> [StudySession] {
        guard let data = defaults.data(forKey: studySessionsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([StudySession].self, from: data)
        } catch {
            throw StorageError.loadFailed
        }
    }
    
    public func deleteStudySession(_ session: StudySession) throws {
        var sessions = try getStudySessions()
        
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
            throw StorageError.notFound
        }
        
        sessions.remove(at: index)
        
        do {
            let data = try encoder.encode(sessions)
            defaults.set(data, forKey: studySessionsKey)
        } catch {
            throw StorageError.deleteFailed
        }
    }
    
    // MARK: - Saved Questions
    public func saveQuestion(_ question: Question) throws {
        var savedQuestions = try getSavedQuestions()
        savedQuestions.append(question)
        
        do {
            let data = try encoder.encode(savedQuestions)
            defaults.set(data, forKey: savedQuestionsKey)
        } catch {
            throw StorageError.saveFailed
        }
    }
    
    public func getSavedQuestions() throws -> [Question] {
        guard let data = defaults.data(forKey: savedQuestionsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([Question].self, from: data)
        } catch {
            throw StorageError.loadFailed
        }
    }
    

    public func saveQuestions(_ questions: [Question]) throws {
        do {
            let data = try encoder.encode(questions)
            defaults.set(data, forKey: savedQuestionsKey)
        } catch {
            throw StorageError.saveFailed
        }
    }
}
