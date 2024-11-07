// Views/Main/HistoryView.swift
import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
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
                
                // History List
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.studySessions.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Complete some study sessions to see them here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
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
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .refreshable {
                viewModel.loadStudySessions()
            }
        }
    }
    
    private var filteredHistory: [StudySession] {
        var sessions = viewModel.studySessions
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break // No filtering needed
        case .languageArts:
            sessions = sessions.filter { $0.problemSet.subject == Subject.languageArts }
        case .math:
            sessions = sessions.filter { $0.problemSet.subject == Subject.math }
        case .saved:
            sessions = sessions.filter { $0.isSaved }
        case .completed:
            sessions = sessions.filter { $0.isCompleted }
        case .inProgress:
            sessions = sessions.filter { !$0.isCompleted }
        }
        
        // Apply search
        if !searchText.isEmpty {
            sessions = sessions.filter {
                $0.problemSet.title.localizedCaseInsensitiveContains(searchText) ||
                $0.problemSet.subject.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return sessions
    }
}
