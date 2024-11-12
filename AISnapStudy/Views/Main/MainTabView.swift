import SwiftUI
import Combine
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var selectedTab = 0
    @StateObject private var studyViewModel: StudyViewModel
    @StateObject private var statViewModel: StatViewModel // StatViewModel 추가
    
    init() {
          let homeVM = HomeViewModel()
          self._homeViewModel = StateObject(wrappedValue: homeVM)
          self._studyViewModel = StateObject(wrappedValue: StudyViewModel(
              homeViewModel: homeVM,
              context: CoreDataService.shared.viewContext
          ))
          self._statViewModel = StateObject(wrappedValue: StatViewModel(context: CoreDataService.shared.viewContext)) // StatViewModel 초기화
      }
     
   
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: homeViewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
           
            if let problemSet = homeViewModel.selectedProblemSet {
                StudyView(
                    questions: problemSet.questions,
                    studyViewModel: studyViewModel,
                    selectedTab: $selectedTab
                )
                .tabItem {
                    Label("Study", systemImage: "book.fill")
                }
                .tag(1)
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
                viewModel: statViewModel, // StatView에 viewModel 전달
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(3)
        }
        .onAppear {
            // StatViewModel에 homeViewModel 설정
            statViewModel.setHomeViewModel(homeViewModel)
        }
        .onChange(of: homeViewModel.selectedProblemSet) { newValue in
            if selectedTab == 1 {
                // Study 탭에서 ProblemSet이 변경되면 상태 리셋
                if let problemSet = newValue {
                    studyViewModel.loadQuestions(problemSet.questions)
                }
            }
        }
        .environmentObject(homeViewModel)
    }
}
