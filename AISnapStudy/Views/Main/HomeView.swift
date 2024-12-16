


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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome Back!")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            if !storeService.subscriptionStatus.isPremium {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.yellow)
                                    Text("\(storeService.subscriptionStatus.dailyQuestionsRemaining) questions remaining")
                                        .foregroundColor(.secondary)
                                }
                                .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Create Questions Button
                        Button(action: {
                            if storeService.subscriptionStatus.dailyQuestionsRemaining > 0 {
                                selectedSubject = .generalKnowledge
                                showQuestionSettings = true
                            } else {
                                // 남은 질문이 없을 때는 업그레이드 안내
                                showUpgradeView = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 28))
                                Text("Create New Questions")
                                    .font(.system(size: 22, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
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
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Favorites Section
                    if !viewModel.favoriteProblemSets.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 24))
                                Text("Favorites")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.favoriteProblemSets) { set in
                                        Button {
                                            Task {
                                                await viewModel.setSelectedProblemSet(set)
                                                if let studyViewModel = viewModel.studyViewModel {
                                                    await studyViewModel.resetState()
                                                    selectedTab = 1
                                                }
                                            }
                                        } label: {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(set.name)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                Text("\(set.questions.count) Questions")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(width: 230)
                                            .padding(16)
                                            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.gray.opacity(0.1), lineWidth: 3)
                                            )
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    
                    // Library Section
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 24))
                            Text("Library")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        .padding(.horizontal, 24)
                        
                        Button {
                            showStudySets = true
                        } label: {
                            HStack {
                                Text("View library question sets")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(viewModel.remoteSets.count) Sets")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 32)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("AI Study")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Spacer()
                        if !storeService.subscriptionStatus.isPremium {
                            Button(action: { showUpgradeView = true }) {
                                Text("Upgrade")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.yellow)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
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
        .sheet(isPresented: $showStudySets) {
            StudySetsView(viewModel: viewModel)
        }
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
                        action: {
                            Task {
                                await viewModel.setSelectedProblemSet(set)
                                if let studyViewModel = viewModel.studyViewModel {
                                    await studyViewModel.resetState()
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

// MARK: - Favorite Card
// 선택적으로 별도의 FavoriteCard 컴포넌트로 분리할 수도 있습니다
struct FavoriteCard: View {
    let set: ProblemSet
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(set.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(set.questions.count) Questions")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .frame(width: 280)
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Downloadable Sets List
struct DownloadableSetsList: View {
    let remoteSets: [RemoteQuestionSet]
    let viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 4) { // 리스트의 간격만 줄임
            ForEach(remoteSets) { set in
                DownloadableSetCard(
                    set: set,
                    action: {
                        Task {
                            await viewModel.downloadQuestionSet(set)
                        }
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

struct DownloadableSetCard: View {
    let set: RemoteQuestionSet
    let action: () -> Void
    
    @StateObject private var storeService = StoreService.shared
    @State private var isDownloading = false
    @State private var isCompleted = false
    @State private var showUpgradeAlert = false
    @State private var showUpgradeView = false
    
    var body: some View {
        CardView {
            HStack(spacing: 12) {
                // 타이틀과 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.title)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        // 문제 수
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("\(set.questionCount)")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        
                        // 난이도
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.blue)
                            Text(set.difficulty)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                
                Spacer()
                
                // 다운로드 버튼
                Button {
                    if storeService.canDownloadMoreSets() {
                        withAnimation {
                            isDownloading = true
                        }
                        storeService.incrementDownloadCount()
                        action()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                isDownloading = false
                                isCompleted = true
                            }
                        }
                    } else {
                        showUpgradeAlert = true
                    }
                } label: {
                    Group {
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if isDownloading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(width: 24, height: 24)
                }
                .disabled(isDownloading || isCompleted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .alert("Upgrade to Premium", isPresented: $showUpgradeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Upgrade") {
                showUpgradeView = true
            }
        } message: {
            Text("You've reached the maximum limit of 5 free downloads. Upgrade to Premium for unlimited access to all question sets!")
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

