import SwiftUI
import Combine
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var selectedTab = 0
   
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: homeViewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
           
            if let problemSet = homeViewModel.selectedProblemSet {
                StudyView(questions: problemSet.questions, homeViewModel: homeViewModel, context: context, selectedTab: $selectedTab)
                    .tabItem {
                        Label("Study", systemImage: "book.fill")
                    }
                    .tag(1)
                    .id("\(problemSet.id)_\(problemSet.questions.count)")
            } else {
                Text("No Problem Set Selected")
                    .tabItem {
                        Label("Study", systemImage: "book.fill")
                    }
                    .tag(1)
            }
           
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)
           
            StatView(
                correctAnswers: homeViewModel.correctAnswers,
                totalQuestions: homeViewModel.totalQuestions,
                context: context
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(3)
        }
        .onChange(of: homeViewModel.selectedProblemSet) { newValue in
            if selectedTab == 1 {
                selectedTab = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 1
                }
            }
        }
        .environmentObject(homeViewModel)
        .onAppear {
            setupNotifications()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
   
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowStudyView"),
            object: nil,
            queue: .main
        ) { _ in
            print("🔄 Switching to Study Tab")
            if let problemSet = homeViewModel.selectedProblemSet {
                withAnimation {
                    selectedTab = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedTab = 1
                    }
                }
            }
        }
    }
}
