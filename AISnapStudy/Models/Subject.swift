
//  Models/Subject.swift

import SwiftUI

public enum Subject: String, Codable, CaseIterable {
    case languageArts = "language_arts"
    case math = "math"
    
    public var color: Color {
        switch self {
        case .languageArts:
            return .blue
        case .math:
            return .green
        }
    }
    
    public var displayName: String {
        switch self {
        case .languageArts:
            return "Language Arts"
        case .math:
            return "Math"
        }
    }
    
    public var icon: String {
        switch self {
        case .languageArts:
            return "book.fill"
        case .math:
            return "function"
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
            return .orange
        case .hard:
            return .red
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
