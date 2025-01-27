import SwiftUI
import Combine
import CoreData

// MARK: - Main View
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedTab: Int
    @State private var showQuestionSettings = false
    @State private var showUpgradeView = false
    @State private var showStudySets = false
    @State private var selectedSubject: DefaultSubject = .generalKnowledge
    @StateObject private var storeService = StoreService.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // iPad에 맞춘 레이아웃 상수
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 800 : .infinity
    }
    
    private var titleFontSize: CGFloat {
        horizontalSizeClass == .regular ? 48 : 32
    }
    
    private var subtitleFontSize: CGFloat {
        horizontalSizeClass == .regular ? 24 : 16
    }
    
    private var buttonHeight: CGFloat {
        horizontalSizeClass == .regular ? 120 : 100
    }
    
    private var cardWidth: CGFloat {
        horizontalSizeClass == .regular ? 400 : 300
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 48 : 32) {
                    // Welcome Section과 Create Questions 버튼
                    VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 32 : 24) {
                        welcomeSection
                        createQuestionsButton
                    }
                    .padding(.horizontal, 24)  // 일관된 패딩 적용
                    
                    // Favorites Section - 항상 표시
                    VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 32 : 20) {
                        // Favorites 헤더
                        HStack(spacing: horizontalSizeClass == .regular ? 16 : 12) {
                            Image(systemName: "star.fill")
                                .font(.system(size: horizontalSizeClass == .regular ? 32 : 24))
                                .foregroundColor(.yellow)
                            Text("Favorites")
                                .font(.system(size: horizontalSizeClass == .regular ? 32 : 24, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        .padding(.horizontal, 24)
                        
                        // Favorites 리스트 또는 빈 상태 메시지
                        if viewModel.favoriteProblemSets.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "star")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                Text("No favorites yet")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                                Text("Your favorite study sets will appear here")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            favoritesList
                        }
                    }
                }
                .padding(.vertical, horizontalSizeClass == .regular ? 48 : 32)
            }
            .frame(maxWidth: maxContentWidth)
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 16 : 8) {
            Text("Welcome Back!")
                .font(.system(size: titleFontSize, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            if !storeService.subscriptionStatus.isPremium {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: horizontalSizeClass == .regular ? 28 : 20))
                        .foregroundColor(.yellow)
                    Text("\(storeService.subscriptionStatus.dailyQuestionsRemaining) questions remaining")
                        .font(.system(size: subtitleFontSize))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var createQuestionsButton: some View {
        Button(action: {
            if storeService.subscriptionStatus.dailyQuestionsRemaining > 0 {
                showQuestionSettings = true
            } else {
                showUpgradeView = true
            }
        }) {
            HStack(spacing: horizontalSizeClass == .regular ? 20 : 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: horizontalSizeClass == .regular ? 36 : 28))
                Text("Create New Questions")
                    .font(.system(size: horizontalSizeClass == .regular ? 28 : 22, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: [
                        storeService.subscriptionStatus.dailyQuestionsRemaining > 0 ? .blue : .gray,
                        storeService.subscriptionStatus.dailyQuestionsRemaining > 0 ? .blue.opacity(0.8) : .gray.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(horizontalSizeClass == .regular ? 24 : 16)
        }
    }
    
    private var favoritesHeader: some View {
        HStack(spacing: horizontalSizeClass == .regular ? 16 : 12) {
            Image(systemName: "star.fill")
                .font(.system(size: horizontalSizeClass == .regular ? 32 : 24))
                .foregroundColor(.yellow)
            Text("Favorites")
                .font(.system(size: horizontalSizeClass == .regular ? 32 : 24, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 40 : 24)
    }
    
    private var favoritesList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: horizontalSizeClass == .regular ? 24 : 16) {
                ForEach(viewModel.favoriteProblemSets) { set in
                    FavoriteCard(set: set, viewModel: viewModel, selectedTab: $selectedTab)
                        .frame(width: cardWidth)
                }
            }
            .padding(.horizontal, horizontalSizeClass == .regular ? 40 : 24)
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack {
                Text("AI Study")
                    .font(.system(size: horizontalSizeClass == .regular ? 42 : 34, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                if !storeService.subscriptionStatus.isPremium {
                    Button(action: { showUpgradeView = true }) {
                        Text("Upgrade")
                            .font(.system(size: horizontalSizeClass == .regular ? 20 : 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 16)
                            .padding(.vertical, horizontalSizeClass == .regular ? 12 : 8)
                            .background(Color.yellow)
                            .cornerRadius(horizontalSizeClass == .regular ? 25 : 20)
                    }
                }
            }
            .padding(.bottom, horizontalSizeClass == .regular ? 16 : 8)
        }
    }
}

struct FavoriteCard: View {
    let set: ProblemSet
    let viewModel: HomeViewModel
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Button {
            Task {
                await viewModel.setSelectedProblemSet(set)
                if let studyViewModel = viewModel.studyViewModel {
                    await studyViewModel.resetState()
                    selectedTab = 1
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 24 : 16) {
                // 상단: 제목과 아이콘
                HStack {
                    // 과목 아이콘
                    Image(systemName: getSubjectIcon(for: set.subject))
                        .font(.system(size: horizontalSizeClass == .regular ? 32 : 24))
                        .foregroundColor(.blue)
                        .frame(width: horizontalSizeClass == .regular ? 56 : 40, height: horizontalSizeClass == .regular ? 56 : 40)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 8 : 4) {
                        Text(set.name)
                            .font(.system(size: horizontalSizeClass == .regular ? 24 : 18, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(set.subject.displayName)
                            .font(.system(size: horizontalSizeClass == .regular ? 18 : 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: horizontalSizeClass == .regular ? 28 : 20))
                        .foregroundColor(.yellow)
                }

                // 하단: 문제 수와 난이도
                HStack(spacing: horizontalSizeClass == .regular ? 24 : 16) {
                    Label(
                        "\(set.questions.count) Questions",
                        systemImage: "doc.text.fill"
                    )
                    .font(.system(size: horizontalSizeClass == .regular ? 18 : 14))
                    .foregroundColor(.secondary)
                    
                    Label(
                        set.educationLevel.displayName,
                        systemImage: "chart.bar.fill"
                    )
                    .font(.system(size: horizontalSizeClass == .regular ? 18 : 14))
                    .foregroundColor(.secondary)
                }
            }
            .padding(horizontalSizeClass == .regular ? 24 : 16)
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(horizontalSizeClass == .regular ? 24 : 16)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: horizontalSizeClass == .regular ? 15 : 10,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getSubjectIcon(for subject: SubjectType) -> String {
        if let defaultSubject = subject as? DefaultSubject {
            switch defaultSubject {
            case .language: return "textformat"
            case .math: return "function"
            case .geography: return "globe"
            case .history: return "clock.fill"
            case .science: return "atom"
            case .generalKnowledge: return "book.fill"
            }
        }
        return "book.fill"
    }
}


// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.title3.bold())
        }
        .padding(.horizontal)
    }
}

// MARK: - Welcome Section
struct WelcomeSection: View {
    let isPremium: Bool
    let remainingQuestions: Int
    @Binding var showUpgradeView: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // 환영 메시지 카드
            CardView {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back!")
                            .font(.title2.bold())
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
            
            // 프리미엄 배너 (무료 사용자만 표시)
            if !isPremium {
                Button(action: { showUpgradeView = true }) {
                    CardView {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Upgrade to Premium")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            Text("\(remainingQuestions) questions left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// CardView 컴포넌트
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Favorites List
struct FavoritesList: View {
    let problemSets: [ProblemSet]
    let viewModel: HomeViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(problemSets) { set in
                    FavoriteCard(
                        set: set,
                        viewModel: viewModel, // viewModel 전달
                        selectedTab: $selectedTab // selectedTab 바인딩 전달
                    )
                }
            }
            .padding(.horizontal)
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
