import SwiftUI



struct ReviewView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @ObservedObject var viewModel: ReviewViewModel
    @StateObject private var subjectManager = SubjectManager.shared
    @State private var showSubjectManagement = false
    @State private var searchText = ""
    @State private var selectedSubject: SubjectType?
   
    public init(viewModel: ReviewViewModel) {
        self.viewModel = viewModel
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
   
   private var allSubjects: [SubjectType] {
       var subjects: [SubjectType] = []
       
       let activeDefaultSubjects = DefaultSubject.allCases.filter { !subjectManager.isDeleted($0) }
       subjects.append(contentsOf: activeDefaultSubjects)
       
       let activeCustomSubjects = subjectManager.customSubjects.filter { $0.isActive }
       subjects.append(contentsOf: activeCustomSubjects)
       
       print("📚 Review - Active Default Subjects: \(activeDefaultSubjects.map { $0.displayName })")
       print("📚 Review - Active Custom Subjects: \(activeCustomSubjects.map { $0.displayName })")
       print("🔒 Review - Hidden Subjects: \(subjectManager.hiddenDefaultSubjects)")
       
       return subjects
   }
   
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // allSubjects를 사용하여 모든 과목 표시
                        ForEach(visibleSubjects, id: \.id) { subject in
                            NavigationLink(
                                destination: ProblemSetsListView(
                                    subject: subject,
                                    problemSets: filterProblemSets(subject: subject)
                                )
                            ) {
                                SubjectCardView(
                                    subject: subject,
                                    problemSetCount: filterProblemSets(subject: subject).count
                                )
                            }
                            .onAppear {
                                print("""
                            📱 Subject Card Appeared:
                            • Subject: \(subject.displayName)
                            """)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Review")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showSubjectManagement = true
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.blue)
                        }
                    }
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
                
            }}
        .onAppear {
            print("📱 ReviewView appeared")
            print("📚 Available subjects: \(visibleSubjects.map { $0.displayName })")
        }
    }
    // 필터링 함수 수정
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

// SavedQuestionsRow 컴포넌트 분리
struct SavedQuestionsRow: View {
    let savedQuestions: [Question]
    let homeViewModel: HomeViewModel
    
    var body: some View {
        NavigationLink(
            destination: SavedQuestionsView(
                questions: savedQuestions,
                homeViewModel: homeViewModel
            )
        ) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.blue)
                Text("Saved Questions")
                    .font(.headline)
                Spacer()
                Text("\(savedQuestions.count)")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// SubjectRow 컴포넌트 분리
struct SubjectListRow: View {
    let subject: SubjectType
    let problemSets: [ProblemSet]
    let subjectManager: SubjectManager  // SubjectManager 인스턴스 필요
    
    var body: some View {
        if !subjectManager.isDeleted(subject.id) {
            NavigationLink(
                destination: ProblemSetsListView(
                    subject: subject,
                    problemSets: filterProblemSets(subject: subject, problemSets: problemSets)
                )
            ) {
                HStack {
                    Image(systemName: subject.icon)
                        .foregroundColor(subject.color)
                    // 여기를 수정 - subject.displayName 대신 subjectManager.getDisplayName 사용
                    if let defaultSubject = subject as? DefaultSubject {
                        Text(subjectManager.getDisplayName(for: defaultSubject))
                    } else {
                        Text(subject.displayName)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
        }
    }
    
    private func filterProblemSets(subject: SubjectType, problemSets: [ProblemSet]) -> [ProblemSet] {
        return problemSets.filter { problemSet in
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
// ReviewView용 DefaultSubjectsSection 컴포넌트
struct ReviewDefaultSubjectsSection: View {
    @ObservedObject var subjectManager: SubjectManager
    let problemSets: [ProblemSet]
    @ObservedObject var homeViewModel: HomeViewModel
    
    var body: some View {
        Section(header: Text("Default Subjects")) {
            ForEach(DefaultSubject.allCases, id: \.id) { subject in
                let filteredSets = problemSets.filter {
                    $0.subjectType == "default" &&
                    $0.subject.rawValue == subject.rawValue
                }.sorted(by: { $0.createdAt > $1.createdAt })
                
                NavigationLink(
                    destination: ProblemSetsListView(
                        subject: subject,
                        problemSets: filteredSets
                    )
                ) {
                    SubjectRow(subject: subject)
                }
            }
        }
    }
}

// ReviewView용 CustomSubjectsSection 컴포넌트
struct ReviewCustomSubjectsSection: View {
    @ObservedObject var subjectManager: SubjectManager
    let problemSets: [ProblemSet]
    @ObservedObject var homeViewModel: HomeViewModel
    
    var body: some View {
        Section(header: Text("Custom Subjects")) {
            ForEach(subjectManager.customSubjects.filter { $0.isActive }) { subject in
                let filteredSets = problemSets.filter { $0.subject.displayName == subject.displayName }
                    .sorted(by: { $0.createdAt > $1.createdAt })
                
                NavigationLink(
                    destination: ProblemSetsListView(
                        subject: subject,
                        problemSets: filteredSets
                    )
                ) {
                    SubjectRow(subject: subject)
                }
            }
        }
    }
}

extension SubjectType {
    func isDeleted(in subjectManager: SubjectManager) -> Bool {
        if let defaultSubject = self as? DefaultSubject {
            return subjectManager.isDeleted(defaultSubject)
        }
        return false
    }
}

// ProblemSetsListView는 그대로 유지


struct ProblemSetsListView: View {
    let subject: SubjectType
    let problemSets: [ProblemSet]
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var isShowingStudyView = false
    @State private var isShowingDeleteAlert = false
    @State private var problemSetToDelete: ProblemSet?
    
    var body: some View {
        List {
            ForEach(problemSets) { problemSet in
                ProblemSetRow(
                    problemSet: problemSet,
                    isShowingStudyView: $isShowingStudyView,
                    isShowingDeleteAlert: $isShowingDeleteAlert,
                    problemSetToDelete: $problemSetToDelete
                )
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("\(subject.displayName) Sets")
        .alert("Delete Problem Set", isPresented: $isShowingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let problemSet = problemSetToDelete {
                    Task {
                        await homeViewModel.deleteProblemSet(problemSet)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this problem set? This action cannot be undone.")
        }
    }
}

// 별도의 row 컴포넌트로 분리
struct ProblemSetRow: View {
   let problemSet: ProblemSet
   @Binding var isShowingStudyView: Bool
   @Binding var isShowingDeleteAlert: Bool
   @Binding var problemSetToDelete: ProblemSet?
   @EnvironmentObject var homeViewModel: HomeViewModel
   @StateObject private var refreshTrigger = RefreshTrigger()
   
   // 이름 변경을 위한 상태 변수
   @State private var displayName: String
   
   init(problemSet: ProblemSet,
        isShowingStudyView: Binding<Bool>,
        isShowingDeleteAlert: Binding<Bool>,
        problemSetToDelete: Binding<ProblemSet?>) {
       self.problemSet = problemSet
       self._isShowingStudyView = isShowingStudyView
       self._isShowingDeleteAlert = isShowingDeleteAlert
       self._problemSetToDelete = problemSetToDelete
       self._displayName = State(initialValue: problemSet.name)
   }
   
   var body: some View {
       Button(action: {
           // ProblemSet 설정
           homeViewModel.setSelectedProblemSet(problemSet)
           
           // StudyViewModel에 직접 questions 설정
           if let studyViewModel = homeViewModel.studyViewModel {
               Task {
                   // 상태 리셋
                   await studyViewModel.resetState()
                   // 문제 로드
                   studyViewModel.loadQuestions(problemSet.questions)
               }
           }
           
           isShowingStudyView = true
       }) {
           ReviewProblemSetCard(
               subject: problemSet.resolvedSubject,
               problemSet: problemSet.copy(withName: displayName),
               onDelete: {
                   problemSetToDelete = problemSet
                   isShowingDeleteAlert = true
               },
               onRename: { newName in
                   Task {
                       await homeViewModel.renameProblemSet(problemSet, newName: newName)
                       // UI 즉시 업데이트
                       await MainActor.run {
                           displayName = newName
                       }
                   }
               }
           )
       }
       .onChange(of: problemSet.name) { newName in
           displayName = newName
       }
   }
}

extension ProblemSet {
    func copy(withName newName: String) -> ProblemSet {
        ProblemSet(
            id: self.id,
            subject: self.subject,
            subjectType: self.subjectType,
            subjectId: self.subjectId,
            subjectName: self.subjectName,
            questions: self.questions,
            createdAt: self.createdAt,
            educationLevel: self.educationLevel,
            name: newName  // 새 이름 사용
        )
    }
}


// StudyView destination을 별도 컴포넌트로 분리
// StudyDestinationView (기존과 동일)
struct StudyDestinationView: View {
    let problemSet: ProblemSet
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    var body: some View {
        Group {
            if let studyViewModel = homeViewModel.studyViewModel {
                StudyView(
                    questions: problemSet.questions,
                    studyViewModel: studyViewModel,
                    selectedTab: .constant(1)
                )
            } else {
                Text("Study ViewModel not available")
            }
        }
    }
}


class RefreshTrigger: ObservableObject {
    @Published var id = UUID()
    
    func refresh() {
        id = UUID()
    }
}


// 과목 행 컴포넌트
struct SubjectRow: View {
    // Style enum to handle different display modes
    enum Style {
        case navigation
        case management
    }
    
    let subject: SubjectType
    let style: Style
    let isDefault: Bool
    
    // Default initializer for navigation style
    init(subject: SubjectType) {
        self.subject = subject
        self.style = .navigation
        self.isDefault = false
    }
    
    // Management style initializer
    init(subject: SubjectType, isDefault: Bool) {
        self.subject = subject
        self.style = .management
        self.isDefault = isDefault
    }
    
    var body: some View {
        HStack {
            Image(systemName: subject.icon)
                .foregroundColor(subject.color)
                .font(style == .management ? .title2 : .body)
            
            Text(subject.displayName)
                .foregroundColor(.primary)
                .font(style == .management ? .body : .headline)
                .padding(.leading, style == .management ? 0 : 8)
            
            if style == .management {
                if isDefault {
                    Spacer()
                    Text("Default")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, style == .management ? 8 : 0)
    }
}
