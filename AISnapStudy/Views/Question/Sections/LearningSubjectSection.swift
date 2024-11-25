import SwiftUI

struct LearningSubjectSection: View {
    @StateObject private var subjectManager = SubjectManager.shared
    @Binding var selectedSubject: SubjectType
    
    var visibleSubjects: [SubjectType] {
        // 기본 과목 중 삭제되지 않은 것들만 필터링
        let defaultSubjects = DefaultSubject.allCases.filter { !subjectManager.isDeleted($0) }
        // 활성화된 커스텀 과목만 필터링
        let customSubjects = subjectManager.customSubjects.filter { $0.isActive }
        
        let subjects = defaultSubjects as [SubjectType] + customSubjects
        
        print("""
        📚 LearningSubjectSection - Visible Subjects:
        • Total Subjects: \(subjects.count)
        • Active Default Subjects: \(defaultSubjects.map { $0.displayName })
        • Active Custom Subjects: \(customSubjects.map { $0.displayName })
        • Hidden Subjects: \(subjectManager.hiddenDefaultSubjects)
        """)
        
        return subjects
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(visibleSubjects, id: \.id) { subject in
                SubjectSelectionButton(
                    subject: subject,
                    isSelected: selectedSubject.id == subject.id
                ) {
                    withAnimation(.spring()) {
                        selectedSubject = subject
                        print("📝 Selected subject: \(subject.displayName)")
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            // 현재 선택된 과목이 삭제되었거나 비활성화된 경우 기본 과목으로 변경
            if let defaultSubject = selectedSubject as? DefaultSubject,
               subjectManager.isDeleted(defaultSubject) {
                // 첫 번째로 사용 가능한 과목을 선택
                if let firstAvailableSubject = visibleSubjects.first {
                    selectedSubject = firstAvailableSubject
                }
            } else if let customSubject = selectedSubject as? CustomSubject,
                      !subjectManager.customSubjects.contains(where: { $0.id == customSubject.id && $0.isActive }) {
                // 첫 번째로 사용 가능한 과목을 선택
                if let firstAvailableSubject = visibleSubjects.first {
                    selectedSubject = firstAvailableSubject
                }
            }
        }
    }
}
