import SwiftUI
import Combine
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var studyViewModel: StudyViewModel
    @StateObject private var reviewViewModel: ReviewViewModel  // 추가
    @State private var selectedTab = 0
    @StateObject private var statViewModel: StatViewModel
    
    
    init() {
        let homeVM = HomeViewModel.shared
        
        self._homeViewModel = StateObject(wrappedValue: homeVM)
        self._studyViewModel = StateObject(wrappedValue: StudyViewModel(
            homeViewModel: homeVM,
            context: CoreDataService.shared.viewContext
        ))
        
        // StudyViewModel 초기화 시점 변경
        let studyVM = StudyViewModel(
            homeViewModel: homeVM,
            context: CoreDataService.shared.viewContext
        )
        self._studyViewModel = StateObject(wrappedValue: studyVM)
        
        let statVM = StatViewModel(
            context: CoreDataService.shared.viewContext,
            homeViewModel: homeVM,
            studyViewModel: studyVM
        )
        // ReviewViewModel 초기화 추가
        let reviewVM = ReviewViewModel(homeViewModel: homeVM)
        self._reviewViewModel = StateObject(wrappedValue: reviewVM)
        
        // StatViewModel도 studyViewModel 참조 추가
        self._statViewModel = StateObject(wrappedValue: StatViewModel(
             context: CoreDataService.shared.viewContext,
             homeViewModel: homeVM,  // homeViewModel 전달
             studyViewModel: studyVM // studyViewModel 전달
         ))
        
        
        self._statViewModel = StateObject(wrappedValue: StatViewModel(
            context: CoreDataService.shared.viewContext
        ))
        
        // homeViewModel에 studyViewModel 설정
        homeVM.setStudyViewModel(studyVM)
        
        // StatViewModel을 StudyViewModel에 연결
        studyVM.setStatViewModel(statVM)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: homeViewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            Group {
                if studyViewModel.isGeneratingQuestions {  // 문제 생성 중일 때
                    GeneratingQuestionsOverlay(
                        questionCount: studyViewModel.totalExpectedQuestions
                    )
                } else if let problemSet = homeViewModel.selectedProblemSet {
                    StudyView(
                        questions: problemSet.questions,
                        studyViewModel: studyViewModel,
                        selectedTab: $selectedTab
                    )
                } else {
                    Text("No Problem Set Selected")
                }
            }
            .tabItem {
                Label("Study", systemImage: "book.fill")
            }
            .tag(1)
            
            ReviewView(viewModel: reviewViewModel)  // viewModel 전달
                .tabItem {
                    Label("Review", systemImage: "clock.fill")
                }
                .tag(2)
            
            StatView(
                viewModel: statViewModel,
                selectedTab: $selectedTab,
                correctAnswers: studyViewModel.correctAnswers,
                totalQuestions: studyViewModel.totalQuestions
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(3)
        }
        .onAppear {
            statViewModel.setHomeViewModel(homeViewModel)
        }
        .onChange(of: homeViewModel.selectedProblemSet) { _ in
             if selectedTab == 1 {
                 if let problemSet = homeViewModel.selectedProblemSet {
                     studyViewModel.loadQuestions(problemSet.questions)
                 }
             }
         }
         .environmentObject(homeViewModel)
    }
}
