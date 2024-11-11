
import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var selectedFilter: HistoryFilter = .all
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(HistoryFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                isSelected: filter == selectedFilter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding()
                }
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Content
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Problem Sets Section
                            if !viewModel.problemSets.isEmpty {
                                Section(header: SectionHeader(title: "Problem Sets")) {
                                    ForEach(viewModel.problemSets) { problemSet in
                                        ProblemSetCard(problemSet: problemSet)
                                            .onTapGesture {
                                                homeViewModel.setSelectedProblemSet(problemSet)
                                            }
                                    }
                                }
                            }
                            
                            // Study History Section
                            if !filteredHistory.isEmpty {
                                Section(header: SectionHeader(title: "Study History")) {
                                    ForEach(filteredHistory) { session in
                                        HistoryCard(session: session)
                                            .swipeActions {
                                                Button(role: .destructive) {
                                                    viewModel.deleteSession(session)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .refreshable {
                viewModel.refreshData()
            }
        }
    }
    
    private var filteredHistory: [StudySession] {
        var sessions = viewModel.studySessions
        
        // Filter by type
        switch selectedFilter {
        case .all:
            break // No filtering needed
        case .language:
            sessions = sessions.filter { $0.problemSet.subject == .language }
        case .math:
            sessions = sessions.filter { $0.problemSet.subject == .math }
        case .geography:
            sessions = sessions.filter { $0.problemSet.subject == .geography }
        case .history:
            sessions = sessions.filter { $0.problemSet.subject == .history }
        case .science:
            sessions = sessions.filter { $0.problemSet.subject == .science }
        case .generalKnowledge:
            sessions = sessions.filter { $0.problemSet.subject == .generalKnowledge }
        case .saved:
            sessions = sessions.filter { $0.isSaved }
        case .completed:
            sessions = sessions.filter { $0.isCompleted }
        case .inProgress:
            sessions = sessions.filter { !$0.isCompleted }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            sessions = sessions.filter {
                $0.problemSet.title.localizedCaseInsensitiveContains(searchText) ||
                $0.problemSet.subject.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by date (newest first)
        return sessions.sorted { $0.startTime > $1.startTime }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}

