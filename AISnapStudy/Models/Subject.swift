
import SwiftUI

// MARK: - Basic Subject Protocol
public protocol SubjectType {
   var id: String { get }
   var displayName: String { get }
   var color: Color { get }
   var icon: String { get }
}



// MARK: - Default System Subjects
public enum DefaultSubject: String, Codable, CaseIterable, SubjectType {
   case language = "language"
   case math = "math"
   case geography = "geography"
   case history = "history"
   case science = "science"
   case generalKnowledge = "general_knowledge"
   
   public var id: String {
       self.rawValue
   }
   
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

// MARK: - Custom User Subject
public struct UserSubject: Identifiable, Codable, Hashable, SubjectType {
   public let id: String
   public var name: String
   public var colorHex: String
   public var iconName: String
   public var createdAt: Date
   public var isActive: Bool
   
   public var displayName: String {
       name
   }
   
   public var color: Color {
       Color(hex: colorHex) ?? .gray
   }
   
   public var icon: String {
       iconName
   }
}

// MARK: - Education Level
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

public class SubjectManager: ObservableObject {
    public static let shared = SubjectManager()
    
    @Published private(set) var customSubjects: [CustomSubject] = []
    @Published private(set) var defaultSubjects: [DefaultSubject] = DefaultSubject.allCases
    @Published private(set) var hiddenDefaultSubjects: Set<String> = []
    
    private init() {
        loadSubjects()
    }
    
    // 기본 과목 숨김 상태 관리
        func toggleSubjectVisibility(_ subject: DefaultSubject) {
            if hiddenDefaultSubjects.contains(subject.id) {
                hiddenDefaultSubjects.remove(subject.id)
            } else {
                hiddenDefaultSubjects.insert(subject.id)
            }
            saveSettings()
        }
        
        func isHidden(_ subject: DefaultSubject) -> Bool {
            hiddenDefaultSubjects.contains(subject.id)
        }
        
        private func saveSettings() {
            // hiddenDefaultSubjects 저장
            UserDefaults.standard.set(Array(hiddenDefaultSubjects), forKey: "hiddenDefaultSubjects")
            // customSubjects 저장
            saveSubjects()
        }
        
        private func loadSettings() {
            // hiddenDefaultSubjects 로드
            if let hidden = UserDefaults.standard.array(forKey: "hiddenDefaultSubjects") as? [String] {
                hiddenDefaultSubjects = Set(hidden)
            }
            // customSubjects 로드
            loadSubjects()
        }
        
        // 모든 활성화된 과목 가져오기 (숨겨지지 않은 기본 과목 + 활성화된 사용자 정의 과목)
        var allSubjects: [any SubjectType] {
            let visibleDefaultSubjects = defaultSubjects.filter { !isHidden($0) }
            let activeCustomSubjects = customSubjects.filter { $0.isActive }
            return visibleDefaultSubjects + activeCustomSubjects
        }
    
    struct CustomSubject: SubjectType, Identifiable, Codable {
        let id: String
        var name: String
        var colorHex: String
        var icon: String
        var isActive: Bool
        
        var displayName: String { name }
        
        var color: Color {
            Color(hex: colorHex) ?? .blue
        }
        
        enum CodingKeys: String, CodingKey {
            case id, name, colorHex, icon, isActive
        }
        
        init(id: String = UUID().uuidString,
             name: String,
             color: Color,
             icon: String,
             isActive: Bool = true) {
            self.id = id
            self.name = name
            self.colorHex = color.toHex() ?? "0000FF"
            self.icon = icon
            self.isActive = isActive
        }
        
        // Custom initializer for cases when we already have the hex color
        init(id: String = UUID().uuidString,
             name: String,
             colorHex: String,
             icon: String,
             isActive: Bool = true) {
            self.id = id
            self.name = name
            self.colorHex = colorHex
            self.icon = icon
            self.isActive = isActive
        }
    }
    
    // CRUD Operations
    func addSubject(name: String, color: Color, icon: String) {
        let newSubject = CustomSubject(
            id: UUID().uuidString,
            name: name,
            color: color,
            icon: icon,
            isActive: true
        )
        customSubjects.append(newSubject)
        saveSubjects()
    }
    
    func updateSubject(_ subject: CustomSubject, newName: String) {
        if let index = customSubjects.firstIndex(where: { $0.id == subject.id }) {
            customSubjects[index].name = newName
            saveSubjects()
        }
    }
    
    func toggleSubjectActive(_ subject: CustomSubject) {
        if let index = customSubjects.firstIndex(where: { $0.id == subject.id }) {
            customSubjects[index].isActive.toggle()
            saveSubjects()
        }
    }
    
    func deleteSubject(_ subject: CustomSubject) {
        customSubjects.removeAll { $0.id == subject.id }
        saveSubjects()
    }
    
    private func saveSubjects() {
        if let encoded = try? JSONEncoder().encode(customSubjects) {
            UserDefaults.standard.set(encoded, forKey: "customSubjects")
        }
    }
    
    private func loadSubjects() {
        if let data = UserDefaults.standard.data(forKey: "customSubjects"),
           let decoded = try? JSONDecoder().decode([CustomSubject].self, from: data) {
            customSubjects = decoded
        }
    }
    
}



// MARK: - Color Extension for Hex
extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        let hex = String(format: "%02lX%02lX%02lX",
                        lroundf(r * 255),
                        lroundf(g * 255),
                        lroundf(b * 255))
        
        return hex
    }
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
