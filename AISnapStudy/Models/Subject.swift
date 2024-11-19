
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
