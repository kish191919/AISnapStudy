


import SwiftUI
import Combine
import CoreData

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var context
    @Binding var selectedTab: Int
    @State private var showQuestionSettings = false
    @State private var showUpgradeView = false // 추가된 State 변수
    @State private var selectedSubject: DefaultSubject = .math
    @StateObject private var subjectManager = SubjectManager.shared
    @StateObject private var storeService = StoreService.shared // StoreService 추가
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // 웰컴 카드
                    WelcomeCard()
                    
                    // Premium 업그레이드 버튼 (무료 사용자에게만 표시)
                    if !storeService.subscriptionStatus.isPremium {
                        PremiumUpgradeButton(
                            remainingQuestions: storeService.subscriptionStatus.dailyQuestionsRemaining,
                            showUpgradeView: $showUpgradeView
                        )
                    }
                    
                    // 즐겨찾기 섹션
                    if !viewModel.favoriteProblemSets.isEmpty {
                        FavoritesSection(
                            problemSets: viewModel.favoriteProblemSets,
                            viewModel: viewModel,
                            selectedTab: $selectedTab
                        )
                    }
                    
                    // 메인 액션 버튼
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
        .sheet(isPresented: $showUpgradeView) {
            PremiumUpgradeView()
        }
    }
}

// Premium 업그레이드 버튼 컴포넌트
struct PremiumUpgradeButton: View {
    let remainingQuestions: Int
    @Binding var showUpgradeView: Bool
    
    var body: some View {
        Button(action: {
            showUpgradeView = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Upgrade to Premium")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(remainingQuestions) questions left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .padding(.horizontal)
    }
}

// 즐겨찾기 섹션 컴포넌트
struct FavoritesSection: View {
    let problemSets: [ProblemSet]
    let viewModel: HomeViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Favorites", systemImage: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(problemSets) { problemSet in
                        FavoriteCard(
                            problemSet: problemSet,
                            onTap: {
                                Task {
                                    viewModel.setSelectedProblemSet(problemSet)
                                    if let studyViewModel = viewModel.studyViewModel {
                                        await studyViewModel.resetState()
                                        studyViewModel.loadQuestions(problemSet.questions)
                                        selectedTab = 1
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
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

// 즐겨찾기 카드 컴포넌트
struct FavoriteCard: View {
    let problemSet: ProblemSet
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // 문제 세트 이름
                Text(problemSet.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 구분선
                Divider()
                
                // 문제 수
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                    
                    Text("\(problemSet.questions.count) Questions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(width: 250)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


extension HomeView {
    private var upgradeButton: some View {
        let storeService = StoreService.shared
        
        return Group {
            if !storeService.subscriptionStatus.isPremium {
                Button(action: {
                    showUpgradeView = true
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Upgrade to Premium")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(storeService.subscriptionStatus.dailyQuestionsRemaining) questions left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .sheet(isPresented: $showUpgradeView) {
                    PremiumUpgradeView()
                }
            }
        }
    }
}
