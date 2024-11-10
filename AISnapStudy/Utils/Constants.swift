// Utils/Constants.swift
import SwiftUI

enum Constants {
    enum API {
        static let baseURL = "https://api.openai.com/v1"
        static let version = "v1"
    }
    
    enum UI {
        static let cornerRadius: CGFloat = 10
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 20
    }
    
    enum Storage {
        static let problemSetsKey = "problemSets"
        static let savedQuestionsKey = "savedQuestions"
        static let userPreferencesKey = "userPreferences"
    }
}
