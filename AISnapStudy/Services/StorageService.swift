
import Foundation

public enum StorageError: Error {
    case saveFailed
    case loadFailed
    case deleteFailed
    case notFound
    case invalidData
    case fileProviderAccessDenied
    case fileCoordinationFailed
}

public class StorageService {
    // MARK: - Properties
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileCoordinator = NSFileCoordinator()
    private let fileManager = FileManager.default
    
    // MARK: - Constants
    private let problemSetsKey = "problemSets"
    private let savedQuestionsKey = "savedQuestions"
    private let studySessionsKey = "studySessions"
    private let maxRetryCount = 3
    private let retryDelay: TimeInterval = 0.5
    
    // MARK: - File System
    private var documentDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private func getDirectoryURL(for type: String) -> URL? {
        documentDirectory?.appendingPathComponent(type)
    }
    
    // MARK: - FileProvider Handling
    private func handleFileProviderAccess<T>(_ operation: @escaping (URL) throws -> T) throws -> T {
        guard checkFileProviderAuthorization() else {
            throw StorageError.fileProviderAccessDenied
        }
        
        guard let url = documentDirectory else {
            throw StorageError.invalidData
        }
        
        var coordinationError: NSError?
        var result: T?
        var operationError: Error?
        
        fileCoordinator.coordinate(writingItemAt: url, options: .forMoving, error: &coordinationError) { coordinatedURL in
            do {
                result = try operation(coordinatedURL)
            } catch {
                operationError = error
            }
        }
        
        if let error = coordinationError {
            throw StorageError.fileCoordinationFailed
        }
        
        if let error = operationError {
            throw error
        }
        
        return result!
    }
    
    private func checkFileProviderAuthorization() -> Bool {
        // 실제 환경에서는 적절한 권한 체크 로직 구현
        return true
    }
    
    // MARK: - Error Handling
    private func handleFileOperation<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch let error as NSError {
            Logger.logError(error, category: "FileOperation")
            
            // 재시도 로직
            for attempt in 1...maxRetryCount {
                Logger.log("Retrying operation (attempt \(attempt)/\(maxRetryCount))", category: "FileOperation")
                do {
                    return try operation()
                } catch {
                    if attempt == maxRetryCount {
                        throw error
                    }
                    Thread.sleep(forTimeInterval: retryDelay)
                }
            }
            throw error
        }
    }
    
    // MARK: - Problem Sets
    public func saveProblemSet(_ problemSet: ProblemSet) throws {
        try handleFileProviderAccess { [weak self] url in
            guard let self = self else { throw StorageError.saveFailed }
            
            try self.handleFileOperation {
                var problemSets = try self.getProblemSets()
                problemSets.append(problemSet)
                
                let data = try self.encoder.encode(problemSets)
                self.defaults.set(data, forKey: self.problemSetsKey)
            }
        }
    }
    
    public func getProblemSets() throws -> [ProblemSet] {
        return try handleFileOperation {
            guard let data = defaults.data(forKey: problemSetsKey) else {
                return []
            }
            
            do {
                return try decoder.decode([ProblemSet].self, from: data)
            } catch {
                Logger.logError(error, category: "ProblemSets")
                throw StorageError.loadFailed
            }
        }
    }
    
    // MARK: - Study Sessions
    public func saveStudySession(_ session: StudySession) throws {
        try handleFileProviderAccess { [weak self] url in
            guard let self = self else { throw StorageError.saveFailed }
            
            try self.handleFileOperation {
                var sessions = try self.getStudySessions()
                sessions.append(session)
                
                let data = try self.encoder.encode(sessions)
                self.defaults.set(data, forKey: self.studySessionsKey)
            }
        }
    }
    
    public func getStudySessions() throws -> [StudySession] {
        return try handleFileOperation {
            guard let data = defaults.data(forKey: studySessionsKey) else {
                return []
            }
            
            do {
                return try decoder.decode([StudySession].self, from: data)
            } catch {
                Logger.logError(error, category: "StudySessions")
                throw StorageError.loadFailed
            }
        }
    }
    
    public func deleteStudySession(_ session: StudySession) throws {
        try handleFileProviderAccess { [weak self] url in
            guard let self = self else { throw StorageError.deleteFailed }
            
            try self.handleFileOperation {
                var sessions = try self.getStudySessions()
                
                guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
                    throw StorageError.notFound
                }
                
                sessions.remove(at: index)
                
                let data = try self.encoder.encode(sessions)
                self.defaults.set(data, forKey: self.studySessionsKey)
            }
        }
    }
    
    public func saveQuestion(_ question: Question) throws {
        try handleFileProviderAccess { [weak self] url in
            guard let self = self else { throw StorageError.saveFailed }
            
            try self.handleFileOperation {
                var savedQuestions = try self.getSavedQuestions()
                savedQuestions.append(question)
                
                let data = try self.encoder.encode(savedQuestions)
                self.defaults.set(data, forKey: self.savedQuestionsKey)
            }
        }
    }
    
    public func getSavedQuestions() throws -> [Question] {
        return try handleFileOperation {
            guard let data = defaults.data(forKey: savedQuestionsKey) else {
                return []
            }
            
            do {
                return try decoder.decode([Question].self, from: data)
            } catch {
                Logger.logError(error, category: "SavedQuestions")
                throw StorageError.loadFailed
            }
        }
    }
    
    public func saveQuestions(_ questions: [Question]) throws {
        try handleFileProviderAccess { [weak self] url in
            guard let self = self else { throw StorageError.saveFailed }
            
            try self.handleFileOperation {
                let data = try self.encoder.encode(questions)
                self.defaults.set(data, forKey: self.savedQuestionsKey)
            }
        }
    }
}

// MARK: - Logger
private class Logger {
    static func log(_ message: String, category: String) {
        #if DEBUG
        print("📝 [\(category)] \(message)")
        #endif
    }
    
    static func logError(_ error: Error, category: String) {
        #if DEBUG
        print("❌ [\(category)] Error: \(error.localizedDescription)")
        #endif
    }
}
