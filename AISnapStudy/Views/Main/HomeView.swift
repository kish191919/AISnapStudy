// File: ./AISnapStudy/Views/Main/HomeView.swift

import SwiftUI
import Combine
import CoreData

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.managedObjectContext) private var context
    @Binding var selectedTab: Int
    @State private var showQuestionSettings = false
    @State private var selectedSubject: Subject = .math
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Create New Questions Button
                    MainActionButton(
                        title: "Create New Questions",
                        icon: "plus.circle.fill"
                    ) {
                        selectedSubject = .math // Default subject
                        showQuestionSettings = true
                    }
                    
                    // Review Questions Button
                    MainActionButton(
                        title: "Review Questions",
                        icon: "book.fill"
                    ) {
                        if let problemSet = viewModel.selectedProblemSet {
                            viewModel.setSelectedProblemSet(problemSet)
                            selectedTab = 1
                        }
                    }
                    .disabled(viewModel.selectedProblemSet == nil)
                    .opacity(viewModel.selectedProblemSet == nil ? 0.5 : 1)
                }
                .padding(.horizontal)
                .padding(.vertical, 32)
            }
            .navigationTitle("Home")
        }
        .sheet(isPresented: $showQuestionSettings) {
            QuestionSettingsView(
                subject: selectedSubject,
                homeViewModel: viewModel,
                selectedTab: $selectedTab  // selectedTab 바인딩 전달
            )
        }
    }
}
