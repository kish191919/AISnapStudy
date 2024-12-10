


import SwiftUI
import Combine
import CoreData

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var context
    @Binding var selectedTab: Int
    @State private var showQuestionSettings = false
    @State private var selectedSubject: DefaultSubject = .math
    @StateObject private var subjectManager = SubjectManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // 상단 웰컴 카드
                    WelcomeCard()
                    
                    // 메인 액션 버튼 (그라데이션 효과 적용)
                    CreateQuestionsButton(action: {
                        selectedSubject = .math
                        showQuestionSettings = true
                    })
                
                }
                .padding(.vertical, 32)
            }
            .navigationTitle("AI Study")
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

// 웰컴 카드 컴포넌트
struct WelcomeCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Ready to learn something new?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

// 메인 액션 버튼 컴포넌트
struct CreateQuestionsButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                
                Text("Create New Questions")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(30)
            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal)
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
