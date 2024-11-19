import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var viewModel: ReviewViewModel
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
                    // Saved Questions Section
                    Section(header: Text("Saved Questions")) {
                        NavigationLink(
                            destination: SavedQuestionsView(
                                questions: viewModel.savedQuestions,
                                homeViewModel: homeViewModel
                            )
                        ) {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(.blue)
                                Text("Saved Questions")
                                    .font(.headline)
                                Spacer()
                                Text("\(viewModel.savedQuestions.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Subject folders
                    ForEach(Subject.allCases, id: \.self) { subject in
                        NavigationLink(
                            destination: ProblemSetsListView(
                                subject: subject,
                                problemSets: filteredAndSortedProblemSets(for: subject)
                            )
                        ) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text(subject.displayName)
                                    .font(.headline)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Review")
                .navigationBarTitleDisplayMode(.inline)  // 이 줄을 추가
                .refreshable {
                    viewModel.refreshData()
                }
            }
        }
        .onAppear {
                    viewModel.setHomeViewModel(homeViewModel)
                }
    }
    
    var problemSets: [ProblemSet] {
        homeViewModel.problemSets
    }
    
    // Subject별로 Problem Sets 필터링 및 정렬하는 메서드
    private func filteredAndSortedProblemSets(for subject: Subject) -> [ProblemSet] {
        return viewModel.problemSets
            .filter { $0.subject == subject }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }
}

struct SavedQuestionsView: View {
    let questions: [Question]
    let homeViewModel: HomeViewModel
    @State private var showStudyView = false
    
    var body: some View {
        List(questions) { question in
            SavedQuestionCard(question: question)
                .onTapGesture {
                    // Create a temporary ProblemSet for the saved question
                    let problemSet = ProblemSet(
                        id: UUID().uuidString,
                        subject: question.subject,
                        questions: [question],
                        createdAt: Date(),
                        educationLevel: .elementary,
                        name: "Saved Question"
                    )
                    homeViewModel.setSelectedProblemSet(problemSet)
                    showStudyView = true
                }
        }
        .navigationTitle("Saved Questions")
        .background(
            NavigationLink(
                isActive: $showStudyView,
                destination: {
                    if let studyViewModel = homeViewModel.studyViewModel {
                        StudyView(
                            questions: [questions[0]],
                            studyViewModel: studyViewModel,
                            selectedTab: .constant(1)
                        )
                    }
                },
                label: { EmptyView() }
            )
        )
    }
}

struct ProblemSetsListView: View {
    let subject: Subject
    let problemSets: [ProblemSet]
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var isShowingStudyView = false
    
    var body: some View {
        List(problemSets) { problemSet in
            Button(action: {
                homeViewModel.setSelectedProblemSet(problemSet)
                isShowingStudyView = true
            }) {
                ReviewProblemSetCard(problemSet: problemSet)
            }
            .background(
                NavigationLink(
                    isActive: $isShowingStudyView,
                    destination: {
                        guard let studyViewModel = homeViewModel.studyViewModel else {
                            return AnyView(Text("Study ViewModel not available"))
                        }
                        return AnyView(
                            StudyView(
                                questions: problemSet.questions,
                                studyViewModel: studyViewModel,
                                selectedTab: .constant(1)
                            )
                        )
                    }
                ) { EmptyView() }
                .hidden()
            )
        }
        .navigationTitle("\(subject.displayName) Sets")
        .listStyle(InsetGroupedListStyle())
    }
}
