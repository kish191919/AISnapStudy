import SwiftUI

import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var viewModel: ReviewViewModel
    @StateObject private var subjectManager = SubjectManager.shared
    @State private var searchText = ""
    
    init() {
        let vm = ReviewViewModel(homeViewModel: HomeViewModel.shared)
        self._viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List {
                    SavedQuestionsSection(
                        savedQuestions: viewModel.savedQuestions,
                        homeViewModel: homeViewModel
                    )
                    
                    DefaultSubjectsSection(
                        viewModel: viewModel,
                        filteredAndSortedProblemSets: filteredAndSortedProblemSets
                    )
                    
                    CustomSubjectsSection(
                        subjectManager: subjectManager,
                        viewModel: viewModel,
                        filteredAndSortedProblemSets: filteredAndSortedProblemSets
                    )
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Review")
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    viewModel.refreshData()
                }
            }
        }
        .onAppear {
            viewModel.setHomeViewModel(homeViewModel)
        }
    }
    
    private func filteredAndSortedProblemSets(for subject: SubjectType) -> [ProblemSet] {
        return viewModel.problemSets
            .filter {
                if let defaultSubject = subject as? DefaultSubject {
                    return $0.subject == defaultSubject
                } else if let userSubject = subject as? UserSubject {
                    return $0.subject.displayName == userSubject.displayName
                }
                return false
            }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }
}

// ProblemSetsListView 구조체 선언 추가
struct ProblemSetsListView: View {
    let subject: SubjectType
    let problemSets: [ProblemSet]
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var isShowingStudyView = false
    
    var body: some View {
        List(problemSets) { problemSet in
            Button(action: {
                homeViewModel.setSelectedProblemSet(problemSet)
                isShowingStudyView = true
            }) {
                ReviewProblemSetCard(subject: problemSet.subject, problemSet: problemSet)
            }
            .background(
                NavigationLink(
                    destination: Group {
                        if let studyViewModel = homeViewModel.studyViewModel {
                            StudyView(
                                questions: problemSet.questions,
                                studyViewModel: studyViewModel,
                                selectedTab: .constant(1)
                            )
                        } else {
                            Text("Study ViewModel not available")
                        }
                    },
                    isActive: $isShowingStudyView
                ) {
                    EmptyView()
                }
            )
        }
        .navigationTitle("\(subject.displayName) Sets")
        .listStyle(InsetGroupedListStyle())
    }
}

struct SavedQuestionsSection: View {
    let savedQuestions: [Question]
    let homeViewModel: HomeViewModel
    
    var body: some View {
        Section(header: Text("Saved Questions")) {
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
}

struct DefaultSubjectsSection: View {
    @StateObject private var subjectManager = SubjectManager.shared
    let viewModel: ReviewViewModel
    let filteredAndSortedProblemSets: (SubjectType) -> [ProblemSet]
    
    var body: some View {
        Section(header: Text("Subjects")) {
            ForEach(subjectManager.allSubjects, id: \.id) { subject in
                NavigationLink(
                    destination: ProblemSetsListView(
                        subject: subject,
                        problemSets: filteredAndSortedProblemSets(subject)
                    )
                ) {
                    SubjectRow(subject: subject)
                }
            }
            
            NavigationLink(destination: SubjectManagementView()) {
                Label("Manage Subjects", systemImage: "gear")
            }
        }
    }
}

struct CustomSubjectsSection: View {
    let subjectManager: SubjectManager
    let viewModel: ReviewViewModel
    let filteredAndSortedProblemSets: (SubjectType) -> [ProblemSet]
    
    var body: some View {
        Section(header: Text("Custom Subjects")) {
            ForEach(subjectManager.customSubjects.filter { $0.isActive }) { subject in
                NavigationLink(
                    destination: ProblemSetsListView(
                        subject: subject,
                        problemSets: filteredAndSortedProblemSets(subject)
                    )
                ) {
                    SubjectRow(subject: subject)
                }
            }
        }
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

struct DefaultSubjectProblemSetList: View {    // 구조체 이름 추가
    let subject: DefaultSubject
    let problemSets: [ProblemSet]
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var isShowingStudyView = false
    
    var body: some View {
        List(problemSets) { problemSet in
            Button(action: {
                homeViewModel.setSelectedProblemSet(problemSet)
                isShowingStudyView = true
            }) {
                ReviewProblemSetCard(subject: problemSet.subject, problemSet: problemSet)
            }
            .background(
                NavigationLink(
                    destination: Group {
                        if let studyViewModel = homeViewModel.studyViewModel {
                            StudyView(
                                questions: problemSet.questions,
                                studyViewModel: studyViewModel,
                                selectedTab: .constant(1)
                            )
                        } else {
                            Text("Study ViewModel not available")
                        }
                    },
                    isActive: $isShowingStudyView
                ) {
                    EmptyView()
                }
            )
        }
        .navigationTitle("\(subject.displayName) Sets")
        .listStyle(InsetGroupedListStyle())
    }
}
