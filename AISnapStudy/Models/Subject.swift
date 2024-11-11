
import SwiftUI

public enum Subject: String, Codable, CaseIterable {
    case language = "language"
    case math = "math"
    case geography = "geography"
    case history = "history"
    case science = "science"
    case generalKnowledge = "general_knowledge"
    
    public var color: Color {
        switch self {
        case .language:
            return .green
        case .math:
            return .green
        case .geography:
            return .green
        case .history:
            return .green
        case .science:
            return .green
        case .generalKnowledge:
            return .green
        }
    }
    
    public var displayName: String {
        switch self {
        case .language:
            return "Language"
        case .math:
            return "Mathematics"
        case .geography:
            return "Geography"
        case .history:
            return "History"
        case .science:
            return "Science"
        case .generalKnowledge:
            return "General Knowledge"
        }
    }
    
    public var icon: String {
        switch self {
        case .language:
            return "textformat"
        case .math:
            return "function"
        case .geography:
            return "globe"
        case .history:
            return "clock.fill"
        case .science:
            return "atom"
        case .generalKnowledge:
            return "book.fill"
        }
    }
}

public enum EducationLevel: String, Codable, CaseIterable {
    case elementary = "elementary"
    case middle = "middle"
    case high = "high"
    case college = "college"
    
    public var displayName: String {
        switch self {
        case .elementary:
            return "Elementary"
        case .middle:
            return "Middle"
        case .high:
            return "High"
        case .college:
            return "College"
        }
    }
    
    public var color: Color {
        switch self {
        case .elementary:
            return .green
        case .middle:
            return .green
        case .high:
            return .green
        case .college:
            return .green
        }
    }
}

public enum Difficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    public var iconName: String {
            switch self {
            case .easy:
                return "1.circle.fill"
            case .medium:
                return "2.circle.fill"
            case .hard:
                return "3.circle.fill"
            }
        }
    
    public var color: Color {
        switch self {
        case .easy:
            return .green
        case .medium:
            return .green
        case .hard:
            return .green
        }
    }
    
    public var displayName: String {
        rawValue.capitalized
    }
    
    public var icon: String {
        switch self {
        case .easy:
            return "1.circle.fill"
        case .medium:
            return "2.circle.fill"
        case .hard:
            return "3.circle.fill"
        }
    }
    
    // 난이도를 숫자로 표현
    public var level: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}
