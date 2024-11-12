import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 검색 바
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Subject 폴더 목록
                List {
                    ForEach(Subject.allCases, id: \.self) { subject in
                        NavigationLink(destination: ProblemSetsListView(subject: subject, problemSets: filteredAndSortedProblemSets(for: subject))) {
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
                .navigationTitle("History")
                .refreshable {
                    viewModel.refreshData()
                }
            }
        }
    }
    
    // Subject별로 Problem Sets 필터링 및 정렬하는 메서드
    private func filteredAndSortedProblemSets(for subject: Subject) -> [ProblemSet] {
        return viewModel.problemSets
            .filter { $0.subject == subject }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }
}

// 선택한 Subject에 대한 Problem Sets 목록을 보여주는 뷰
struct ProblemSetsListView: View {
    let subject: Subject
    let problemSets: [ProblemSet]
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    var body: some View {
        List(problemSets) { problemSet in
            ProblemSetCard(problemSet: problemSet)
                .onTapGesture {
                    homeViewModel.setSelectedProblemSet(problemSet)
                }
        }
        .navigationTitle("\(subject.displayName) Sets")
        .listStyle(InsetGroupedListStyle())
    }
}


