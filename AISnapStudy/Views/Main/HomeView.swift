


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
    @State private var selectedSubject: DefaultSubject = .generalKnowledge
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
                    
                    // 원격 문제 세트 섹션 추가
                    if !viewModel.remoteSets.isEmpty {
                        RemoteQuestionSetsSection(
                            remoteSets: viewModel.remoteSets,
                            viewModel: viewModel
                        )
                    }
                    
                    // 메인 액션 버튼
                    CreateQuestionsButton(action: {
                        selectedSubject = .generalKnowledge
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

// 원격 문제 세트 섹션 컴포넌트
struct RemoteQuestionSetsSection: View {
    let remoteSets: [RemoteQuestionSet]
    let viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Question Sets")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            ForEach(remoteSets) { remoteSet in
                RemoteQuestionSetCard(
                    set: remoteSet,
                    onDownload: {
                        Task {
                            await viewModel.downloadQuestionSet(remoteSet)
                        }
                    }
                )
                .padding(.horizontal)
            }
        }
    }
}

// 원격 문제 세트 카드 컴포넌트
struct RemoteQuestionSetCard: View {
    let set: RemoteQuestionSet
    let onDownload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(set.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(set.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("\(set.questionCount) questions")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onDownload) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Download")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
                Text("Favorite Sets")  // 더 세련된 텍스트로 변경
                    .font(.system(size: 20, weight: .semibold))  // 폰트 스타일 수정
                    .foregroundColor(.primary)
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
                                    await viewModel.setSelectedProblemSet(problemSet)
                                    if let studyViewModel = viewModel.studyViewModel {
                                        await studyViewModel.resetState()
                                        // 직접 loadQuestions 호출하지 않음
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
