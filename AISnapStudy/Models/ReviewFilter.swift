
import Foundation

enum ReviewFilter: String, CaseIterable {
    case all = "All"
    case language = "Language"
    case math = "Math"
    case geography = "Geography"
    case history = "History"
    case science = "Science"
    case generalKnowledge = "General Knowledge"
    case saved = "Saved"
    case completed = "Completed"
    case inProgress = "In Progress"
}

