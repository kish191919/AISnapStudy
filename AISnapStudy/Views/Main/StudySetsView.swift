import SwiftUI


// 정렬 옵션을 위한 enum
enum SortOption: String, CaseIterable {
    case name = "Name"
    case questionCount = "Questions"
    case difficulty = "Education"
}

struct StudySetsView: View {
   @StateObject private var storeService = StoreService.shared
   let viewModel: HomeViewModel
   @Environment(\.dismiss) private var dismiss
   @State private var selectedSort: SortOption = .name
   @State private var isAscending = true
   @Environment(\.colorScheme) var colorScheme
   
    private var sortedSets: [RemoteQuestionSet] {
        var sets = viewModel.remoteSets
        
        switch selectedSort {
        case .name:
            sets.sort { (set1, set2) in
                isAscending ? set1.title < set2.title : set1.title > set2.title
            }
        case .questionCount:
            sets.sort { (set1, set2) in
                isAscending ? set1.questionCount < set2.questionCount : set1.questionCount > set2.questionCount
            }
        case .difficulty:
            let difficultyOrder = ["Elementary": 0, "Middle": 1, "High": 2, "College": 3]
            sets.sort { (set1, set2) in
                let order1 = difficultyOrder[set1.difficulty] ?? 0
                let order2 = difficultyOrder[set2.difficulty] ?? 0
                return isAscending ? order1 < order2 : order1 > order2
            }
        }
        
        return sets
    }
   
   var body: some View {
       NavigationView {
           ScrollView {
               VStack(spacing: 20) {
                   // 무료 사용자를 위한 다운로드 상태 표시
                   if !storeService.subscriptionStatus.isPremium {
                       VStack(spacing: 8) {
                           Text("Free Downloads: \(storeService.subscriptionStatus.downloadedSetsCount)/5")
                               .font(.subheadline)
                               .foregroundColor(.secondary)
                           
                           if storeService.remainingDownloads > 0 {
                               Text("\(storeService.remainingDownloads) downloads remaining")
                                   .font(.caption)
                                   .foregroundColor(.blue)
                           }
                       }
                       .padding()
                       .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                       .cornerRadius(12)
                       .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                       .padding(.horizontal)
                   }
                   
                   // 정렬된 문제 세트 목록
                   VStack(spacing: 2) {
                       ForEach(sortedSets) { set in
                           DownloadableSetCard(
                               set: set,
                               action: {
                                   Task {
                                       await viewModel.downloadQuestionSet(set)
                                   }
                               }
                           )
                       }
                   }
                   .padding(.vertical, 8)
               }
           }
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
               ToolbarItem(placement: .navigationBarLeading) {
                   Text("Study Sets")
                       .font(.system(size: 22, weight: .semibold))
                       .foregroundColor(.primary)
               }
               
               ToolbarItem(placement: .navigationBarTrailing) {
                   HStack(spacing: 16) {
                       Menu {
                           Picker("Sort by", selection: $selectedSort) {
                               ForEach(SortOption.allCases, id: \.self) { option in
                                   Text(option.rawValue)
                               }
                           }
                           
                           Divider()
                           
                           Button(action: { isAscending.toggle() }) {
                               HStack {
                                   Text(isAscending ? "Ascending" : "Descending")
                                   Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                               }
                           }
                       } label: {
                           Image(systemName: "arrow.up.arrow.down")
                               .foregroundColor(.blue)
                       }
                       
                       Button("Done") {
                           dismiss()
                       }
                   }
               }
           }
       }
   }
}




// LocalSetCard 컴포넌트
struct LocalSetCard: View {
    let set: ProblemSet
    let viewModel: HomeViewModel
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(set.name)
                            .font(.headline)
                        Text("\(set.questions.count) Questions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await viewModel.toggleFavorite(set)
                        }
                    } label: {
                        Image(systemName: set.isFavorite ? "star.fill" : "star")
                            .foregroundColor(set.isFavorite ? .yellow : .gray)
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}
