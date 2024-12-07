


import SwiftUI
import Combine
import CoreData

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.managedObjectContext) private var context
    @Binding var selectedTab: Int
    @State private var showQuestionSettings = false
    @State private var selectedSubject: DefaultSubject = .math
    @StateObject private var subjectManager = SubjectManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Create New Questions Button
                    MainActionButton(
                        title: "Create New Questions",
                        icon: "plus.circle.fill"
                    ) {
                        selectedSubject = .math
                        showQuestionSettings = true
                    }
                    
                    // Review Questions Button
                    MainActionButton(
                        title: "Review Questions",
                        icon: "book.fill"
                    ) {
                        if let problemSet = viewModel.selectedProblemSet {
                            viewModel.setSelectedProblemSet(problemSet)
                            selectedTab = 1
                        }
                    }
                    .disabled(viewModel.selectedProblemSet == nil)
                    .opacity(viewModel.selectedProblemSet == nil ? 0.5 : 1)
                    
                    // 사용자 정의 과목 리스트 (옵션)
                    if !subjectManager.customSubjects.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom Subjects")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(subjectManager.customSubjects.filter { $0.isActive }) { subject in
                                        CustomSubjectButton(subject: subject) {
                                            showQuestionSettings = true
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical, 32)
            }
            .navigationTitle("Home")
        }
        .sheet(isPresented: $showQuestionSettings) {
            QuestionSettingsView(
                subject: selectedSubject,
                homeViewModel: viewModel,
                selectedTab: $selectedTab
            )
        }
    }
}

struct CustomSubjectButton: View {
    let subject: CustomSubject  // SubjectManager.CustomSubject에서 CustomSubject로 변경
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: subject.icon)
                    .font(.system(size: 24))
                    .foregroundColor(subject.color)
                Text(subject.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// SubjectType 확장
extension DefaultSubject {
    static var defaultSubject: DefaultSubject {
        return .math
    }
    
    public var displayName: String {
        SubjectManager.shared.modifiedDefaultSubjects[self.id] ?? defaultDisplayName
    }
    
    // 원래의 displayName을 defaultDisplayName으로 이동
    private var defaultDisplayName: String {
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
}
