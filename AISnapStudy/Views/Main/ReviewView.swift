import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @ObservedObject var viewModel: ReviewViewModel
    @StateObject private var subjectManager = SubjectManager.shared
    @State private var showSubjectManagement = false
    @State private var searchText = ""
    @State private var selectedSubject: SubjectType?
    @Binding var selectedTab: Int
   
    public init(viewModel: ReviewViewModel, selectedTab: Binding<Int>) {
        self.viewModel = viewModel
        self._selectedTab = selectedTab
    }
    
    private var visibleSubjects: [SubjectType] {
        let defaultSubjects = DefaultSubject.allCases.filter { !subjectManager.isDeleted($0) }
        let customSubjects = subjectManager.customSubjects.filter { $0.isActive }
        
        let subjects = defaultSubjects as [SubjectType] + customSubjects
        
        print("""
        📚 ReviewView - Visible Subjects:
        • Total Subjects: \(subjects.count)
        • Active Default Subjects: \(defaultSubjects.map { $0.displayName })
        • Active Custom Subjects: \(customSubjects.map { $0.displayName })
        • Hidden Subjects: \(subjectManager.hiddenDefaultSubjects)
        """)
        
        return subjects
    }
   
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 5) {
                    Spacer()
                        .frame(height: 5)
                    
                    // Add Saved Questions Card
                    NavigationLink(
                        destination: SavedQuestionsView(selectedTab: $selectedTab)
                    ) {
                        SavedQuestionsCard(savedCount: homeViewModel.savedQuestions.count)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 5) {
                        ForEach(visibleSubjects, id: \.id) { subject in
                            NavigationLink(
                                destination: ProblemSetsListView(
                                    subject: subject,
                                    problemSets: filterProblemSets(subject: subject),
                                    selectedTab: $selectedTab
                                )
                            ) {
                                SubjectCardView(
                                    subject: subject,
                                    problemSetCount: filterProblemSets(subject: subject).count
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Review")
                            .font(.system(size: 34, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ReviewToolbarButtons(showSubjectManagement: $showSubjectManagement)
                    }
                    .frame(maxWidth: .infinity)                }
            }
            .sheet(isPresented: $showSubjectManagement) {
                NavigationView {
                    SubjectManagementView()
                        .navigationTitle("Manage Subjects")
                        .navigationBarItems(
                            trailing: Button("Done") {
                                showSubjectManagement = false
                            }
                        )
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func filterProblemSets(subject: SubjectType) -> [ProblemSet] {
        return homeViewModel.problemSets.filter { problemSet in
            if let defaultSubject = subject as? DefaultSubject {
                return problemSet.subjectType == "default" &&
                       problemSet.subject.rawValue == defaultSubject.rawValue
            } else if let customSubject = subject as? CustomSubject {
                return problemSet.subjectType == "custom" &&
                       problemSet.subjectId == customSubject.id
            }
            return false
        }
    }
}

// 분리된 툴바 버튼 컴포넌트
struct ReviewToolbarButtons: View {
    @Binding var showSubjectManagement: Bool
    @State private var showHelp = false  // 도움말 표시 상태 추가
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var buttonSpacing: CGFloat {
        horizontalSizeClass == .regular ? 24 : 16  // iPad에서는 더 큰 간격
    }
    
    var body: some View {
        HStack(spacing: buttonSpacing) {
            Button(action: {
                showHelp = true  // 도움말 버튼 클릭 시 showHelp를 true로 설정
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: horizontalSizeClass == .regular ? 24 : 20))
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                showSubjectManagement = true
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: horizontalSizeClass == .regular ? 24 : 20))
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, horizontalSizeClass == .regular ? 12 : 8)
        .sheet(isPresented: $showHelp) {
            NavigationStack {
                ReviewHelpContentView()
                    .navigationTitle("Review Help")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showHelp = false
                            }
                        }
                    }
            }
        }
    }
}

struct ReviewHelpContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                helpSection(
                    title: "Question Sets",
                    content: "• Each subject contains multiple question sets\n• Select a question set to start studying\n• You can favorite sets for quick access\n• Edit mode allows you to rename or delete sets"
                )
                
                helpSection(
                    title: "Saved Questions",
                    content: "• Access your saved questions from any set\n• Review specific questions you want to focus on\n• Bookmark important questions while studying"
                )
                
                helpSection(
                    title: "Subject Management",
                    content: "• Create custom subjects\n• Organize your study materials"
                )
                
                helpSection(
                    title: "Tips",
                    content: "• Use favorites for important sets\n• Create subjects for better organization\n• Save questions you want to review later"
                )
            }
            .padding()
        }
    }
    
    private func helpSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// Navigation Bar에서의 제목 컴포넌트도 분리
struct ReviewNavigationTitle: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Text("Review")
            .font(.system(
                size: horizontalSizeClass == .regular ? 38 : 34,
                weight: .bold
            ))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 16)
    }
}

// 너비 제한을 위한 래퍼 뷰
struct ContentWidthWrapper<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            content
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

// Add new SavedQuestionsCard component
struct SavedQuestionsCard: View {
    let savedCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Saved Questions")
                    .font(.headline)
                Text("\(savedCount) questions saved")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}

struct SubjectCardView: View {
    let subject: SubjectType
    let problemSetCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: subject.icon)
                .font(.system(size: 32))
                .foregroundColor(subject.color)
            
            Text(subject.displayName)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text("\(problemSetCount) sets")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(subject.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(subject.color.opacity(0.2), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }
}

struct ProblemSetsListView: View {
    let subject: SubjectType
    let problemSets: [ProblemSet]
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Binding var selectedTab: Int
    @State private var isEditMode = false
    @State private var showHelpAlert = false
    @State private var localProblemSets: [ProblemSet] = []
    
    // 알림 관련 상태
    @State private var isShowingDeleteAlert = false
    @State private var problemSetToDelete: ProblemSet?
    @State private var showingMergeAlert = false
    @State private var mergingProblemSets: (source: ProblemSet, target: ProblemSet)?
    @State private var mergeSetName = ""
    
    var body: some View {
        ProblemSetListContainer(
            localProblemSets: localProblemSets,
            isEditMode: isEditMode,
            selectedTab: $selectedTab,
            problemSetToDelete: $problemSetToDelete,
            isShowingDeleteAlert: $isShowingDeleteAlert
        )
        .navigationTitle(subject.displayName)
        .toolbar {
            ProblemSetToolbar(
                isEditMode: $isEditMode,
                showHelpAlert: $showHelpAlert
            )
        }
        .onAppear { localProblemSets = problemSets }
        .onChange(of: homeViewModel.problemSets) { newProblemSets in
            updateLocalProblemSets(newProblemSets)
        }
        .alert("Delete Problem Set", isPresented: $isShowingDeleteAlert) {
            DeleteAlertButtons(
                problemSetToDelete: problemSetToDelete,
                homeViewModel: homeViewModel
            )
        }
    }
    
    private func updateLocalProblemSets(_ newProblemSets: [ProblemSet]) {
        localProblemSets = newProblemSets.filter { set in
            if let defaultSubject = subject as? DefaultSubject {
                return set.subjectType == "default" && set.subject.rawValue == defaultSubject.rawValue
            } else if let customSubject = subject as? CustomSubject {
                return set.subjectType == "custom" && set.subjectId == customSubject.id
            }
            return false
        }
    }
}

// MARK: - Supporting Views
private struct ProblemSetListContainer: View {
    let localProblemSets: [ProblemSet]
    let isEditMode: Bool
    @Binding var selectedTab: Int
    @Binding var problemSetToDelete: ProblemSet?
    @Binding var isShowingDeleteAlert: Bool
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var refreshID = UUID() // 추가
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                LazyVStack(spacing: 12) {
                    ForEach(localProblemSets) { problemSet in
                        ProblemSetItem(
                            problemSetId: problemSet.id,  // ID만 전달
                            isEditMode: isEditMode,
                            selectedTab: $selectedTab,
                            problemSetToDelete: $problemSetToDelete,
                            isShowingDeleteAlert: $isShowingDeleteAlert,
                            onFavoriteToggle: {
                                Task {
                                    await homeViewModel.toggleFavorite(problemSet)
                                    // UI 강제 새로고침
                                    await MainActor.run {
                                        refreshID = UUID()
                                    }
                                }
                            }
                        )
                    }
                }
            }
            .padding(.vertical)
            .id(refreshID) // 추가
        }
    }
}

private struct ProblemSetItem: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    let problemSetId: String  // problemSet 대신 ID만 저장
    let isEditMode: Bool
    @Binding var selectedTab: Int
    @Binding var problemSetToDelete: ProblemSet?
    @Binding var isShowingDeleteAlert: Bool
    let onFavoriteToggle: () -> Void

    // 필요할 때마다 최신 problemSet 데이터 조회
    private var problemSet: ProblemSet? {
        homeViewModel.problemSets.first { $0.id == problemSetId }
    }
    
    // 생성자 수정
    init(problemSetId: String,
         isEditMode: Bool,
         selectedTab: Binding<Int>,
         problemSetToDelete: Binding<ProblemSet?>,
         isShowingDeleteAlert: Binding<Bool>,
         onFavoriteToggle: @escaping () -> Void) {
        self.problemSetId = problemSetId
        self.isEditMode = isEditMode
        self._selectedTab = selectedTab
        self._problemSetToDelete = problemSetToDelete
        self._isShowingDeleteAlert = isShowingDeleteAlert
        self.onFavoriteToggle = onFavoriteToggle
    }
    
    var body: some View {
        Group {
            if let currentProblemSet = problemSet {
                ReviewProblemSetCard(
                    subject: currentProblemSet.resolvedSubject,
                    problemSet: currentProblemSet,
                    isEditMode: isEditMode,
                    onDelete: {
                        problemSetToDelete = currentProblemSet
                        isShowingDeleteAlert = true
                    },
                    onRename: { newName in
                        Task {
                            await homeViewModel.renameProblemSet(currentProblemSet, newName: newName)
                        }
                    },
                    onFavoriteToggle: onFavoriteToggle
                )
                .onTapGesture {
                    handleTap(problemSet: currentProblemSet)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func handleTap(problemSet: ProblemSet) {
        Task {
            await homeViewModel.setSelectedProblemSet(problemSet)
            if let studyViewModel = homeViewModel.studyViewModel {
                await studyViewModel.resetState()
                await MainActor.run {
                    withAnimation {
                        selectedTab = 1
                    }
                }
            }
        }
    }
}

private struct ProblemSetToolbar: ToolbarContent {
    @Binding var isEditMode: Bool
    @Binding var showHelpAlert: Bool
    @State private var showAlert = false  // 도움말 알림을 위한 상태 추가
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                Button(action: {
                    showAlert = true  // 도움말 버튼 클릭 시 알림 표시
                }) {
                    Image(systemName: "questionmark.circle")
                        .imageScale(.large)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    withAnimation {
                        isEditMode.toggle()
                    }
                }) {
                    Image(systemName: isEditMode ? "checkmark.circle.fill" : "pencil.circle")
                        .imageScale(.large)
                        .foregroundColor(isEditMode ? .green : .blue)
                }
            }
            .alert("How to Use", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("• Tap a problem set to start reviewing\n• Use star icon to mark favorites\n• Edit mode lets you rename or delete sets\n• Drag and drop sets to combine them")
                    .multilineTextAlignment(.leading)
            }
        }
    }
}
private struct DeleteAlertButtons: View {
    let problemSetToDelete: ProblemSet?
    let homeViewModel: HomeViewModel
    
    var body: some View {
        Group {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let problemSet = problemSetToDelete {
                    Task {
                        await homeViewModel.deleteProblemSet(problemSet)
                    }
                }
            }
        }
    }
}
