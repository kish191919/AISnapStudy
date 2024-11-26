
import SwiftUI

// MARK: - Basic Subject Protocol
public protocol SubjectType: Codable {
   var id: String { get }
   var displayName: String { get }
   var color: Color { get }
   var icon: String { get }
   var rawValue: String { get }  // 추가
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
    
    // 기존의 displayName을 baseDisplayName으로 변경
    private var baseDisplayName: String {
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

// CustomSubject 구조체 추가
public struct CustomSubject: SubjectType, Codable, Identifiable {
    public let id: String
    public var name: String  // let을 var로 변경
    public let icon: String
    public var isActive: Bool
    
    // SubjectType 프로토콜 요구사항
    public var displayName: String { name }
    public var color: Color { .green }  // 계산 프로퍼티로 변경
    public var rawValue: String { id }  // 추가: id를 rawValue로 사용
    
    // 기본 초기화자
    public init(id: String = UUID().uuidString,
                name: String,
                icon: String,
                isActive: Bool = true) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isActive = isActive
    }
    
    // Codable 구현
    enum CodingKeys: String, CodingKey {
        case id, name, icon, isActive
        // color는 제외 - 항상 .green을 사용할 것이므로
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(isActive, forKey: .isActive)
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
    
    public var rawValue: String { id }  // 추가: id를 rawValue로 사용
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
    
    private init() {
        loadSettings()
        loadCustomSubjects()
    }
    
    @Published private(set) var customSubjects: [CustomSubject] = []
    @Published private(set) var hiddenDefaultSubjects: Set<String> = []
    @Published private(set) var modifiedDefaultSubjects: [String: String] = [:]
    
    // 새로운 과목 추가
    func addCustomSubject(name: String, icon: String = "book.circle") {
        let newSubject = CustomSubject(
            id: UUID().uuidString,
            name: name,
            icon: icon,
            isActive: true
        )
        customSubjects.append(newSubject)
        saveCustomSubjects()
    }
    
    // 과목 제거
    func removeCustomSubject(_ subject: CustomSubject) {
        customSubjects.removeAll { $0.id == subject.id }
        saveCustomSubjects()
    }
    
    // UserDefaults를 사용한 저장 및 로드
    private func saveCustomSubjects() {
        if let encoded = try? JSONEncoder().encode(customSubjects) {
            UserDefaults.standard.set(encoded, forKey: "customSubjects")
        }
    }
    
    private func loadCustomSubjects() {
        if let data = UserDefaults.standard.data(forKey: "customSubjects"),
           let decoded = try? JSONDecoder().decode([CustomSubject].self, from: data) {
            self.customSubjects = decoded
        }
    }
    
    // "삭제된" 과목 복원을 위한 백업 저장
    private var deletedSubjectsBackup: Set<String> = []
    
    func isDeleted(_ subjectId: String) -> Bool {
            return hiddenDefaultSubjects.contains(subjectId)
        }
        
    func toggleDefaultSubject(_ subject: DefaultSubject) {
        print("🔄 Toggling subject visibility: \(subject.displayName)")
        if hiddenDefaultSubjects.contains(subject.id) {
            print("➖ Removing from hidden: \(subject.id)")
            hiddenDefaultSubjects.remove(subject.id)
        } else {
            print("➕ Adding to hidden: \(subject.id)")
            hiddenDefaultSubjects.insert(subject.id)
        }
        saveAndNotify()
        print("📊 Current hidden subjects: \(hiddenDefaultSubjects)")
    }
        
    private func saveAndNotify() {
        saveSettings()
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Self.subjectsDidChangeNotification,
                object: self
            )
        }
    }
    
    // 로드 시 UserDefaults에서 설정 불러오기
    private func loadSettings() {
        if let hidden = UserDefaults.standard.array(forKey: "hiddenDefaultSubjects") as? [String] {
            hiddenDefaultSubjects = Set(hidden)
        }
        modifiedDefaultSubjects = UserDefaults.standard.dictionary(forKey: "modifiedDefaultSubjects") as? [String: String] ?? [:]
        if let data = UserDefaults.standard.data(forKey: "customSubjects"),
           let decoded = try? JSONDecoder().decode([CustomSubject].self, from: data) {
            customSubjects = decoded
        }
        // 변경사항을 알림
        notifySubjectsChange()
    }

    
    // 과목 이름 업데이트 함수 수정
    func updateDefaultSubjectName(_ subject: DefaultSubject, newName: String) {
        print("✏️ Updating name for subject: \(subject.displayName) to: \(newName)")
        modifiedDefaultSubjects[subject.id] = newName
        print("💾 Current modified names: \(modifiedDefaultSubjects)")
        saveAndNotify()
    }
    
    // 과목 이름 초기화 함수 수정
    func resetDefaultSubjectName(_ subject: DefaultSubject) {
        modifiedDefaultSubjects.removeValue(forKey: subject.id)
        saveAndNotify()
    }
    
    // 변경사항 알림을 위한 NotificationCenter 키
    static let subjectsDidChangeNotification = Notification.Name("SubjectsDidChange")
    
    private func notifySubjectsChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Self.subjectsDidChangeNotification,
                object: self
            )
        }
    }
    
    
    // 과목 "삭제" (실제로는 숨김)
    func deleteDefaultSubject(_ subject: DefaultSubject) {
        hiddenDefaultSubjects.insert(subject.id)
        deletedSubjectsBackup.insert(subject.id)
        saveSettings()
        notifySubjectsChange()
    }
    
    // 삭제된 과목 복원
    func restoreDeletedSubject(_ subject: DefaultSubject) {
        hiddenDefaultSubjects.remove(subject.id)
        deletedSubjectsBackup.remove(subject.id)
        saveSettings()
        notifySubjectsChange()
    }
    
    // 과목이 "삭제"되었는지 확인
    func isDeleted(_ subject: DefaultSubject) -> Bool {
        hiddenDefaultSubjects.contains(subject.id)
    }
    
    // 사용 가능한(삭제되지 않은) 과목들 가져오기
    var availableSubjects: [any SubjectType] {
        let visibleDefaultSubjects = DefaultSubject.allCases.filter { !hiddenDefaultSubjects.contains($0.id) }
        let activeCustomSubjects = customSubjects.filter { $0.isActive }
        return visibleDefaultSubjects + activeCustomSubjects
    }
    
    // 저장된 설정에 삭제된 과목 정보 포함
    private func saveSettings() {
        UserDefaults.standard.set(Array(hiddenDefaultSubjects), forKey: "hiddenDefaultSubjects")
        UserDefaults.standard.set(Array(deletedSubjectsBackup), forKey: "deletedSubjectsBackup")
        UserDefaults.standard.set(modifiedDefaultSubjects, forKey: "modifiedDefaultSubjects")
        if let encoded = try? JSONEncoder().encode(customSubjects) {
            UserDefaults.standard.set(encoded, forKey: "customSubjects")
        }
    }
    
    
    

    
    // 기본 과목 이름 관리 메서드 추가
    func getDisplayName(for subject: DefaultSubject) -> String {
        return modifiedDefaultSubjects[subject.id] ?? subject.displayName
    }
    

    
    // CustomSubject 관리 메서드
    func updateSubject(_ subject: CustomSubject, newName: String) {
        if let index = customSubjects.firstIndex(where: { $0.id == subject.id }) {
            customSubjects[index].name = newName
            saveSettings()
        }
    }
    
    func toggleSubjectActive(_ subject: CustomSubject) {
        if let index = customSubjects.firstIndex(where: { $0.id == subject.id }) {
            customSubjects[index].isActive.toggle()
            saveSettings()
        }
    }
    
    func deleteSubject(_ subject: CustomSubject) {
        customSubjects.removeAll { $0.id == subject.id }
        saveSettings()
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
        
        // 과목이 숨겨져 있는지 확인
        func isHidden(_ subject: DefaultSubject) -> Bool {
            hiddenDefaultSubjects.contains(subject.id)
        }
        
        
        // 모든 활성화된 과목 가져오기 (숨겨지지 않은 기본 과목 + 활성화된 사용자 정의 과목)
    var allSubjects: [SubjectType] {
        var subjects: [SubjectType] = Array(DefaultSubject.allCases)
        subjects.append(contentsOf: customSubjects.filter { $0.isActive })
        return subjects
    }
    
    
    // 과목 추가 메서드 수정
    func addSubject(name: String, icon: String) {  // color 매개변수 제거
        let newSubject = CustomSubject(
            id: UUID().uuidString,
            name: name,
            icon: icon,
            isActive: true
        )
        customSubjects.append(newSubject)
        saveSubjects()
        
        print("""
        ✅ Added new custom subject:
        • Name: \(name)
        • ID: \(newSubject.id)
        • Total custom subjects: \(customSubjects.count)
        """)
    }
    
    // 저장 메서드 수정
    private func saveSubjects() {
        if let encoded = try? JSONEncoder().encode(customSubjects) {
            UserDefaults.standard.set(encoded, forKey: "customSubjects")
            print("💾 Saved \(customSubjects.count) custom subjects to UserDefaults")
        }
    }
    
    // 로드 메서드 수정
    private func loadSubjects() {
        if let data = UserDefaults.standard.data(forKey: "customSubjects"),
           let decoded = try? JSONDecoder().decode([CustomSubject].self, from: data) {
            customSubjects = decoded
            print("📤 Loaded \(customSubjects.count) custom subjects from UserDefaults")
            print("📚 Custom Subjects: \(customSubjects.map { $0.displayName })")
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
