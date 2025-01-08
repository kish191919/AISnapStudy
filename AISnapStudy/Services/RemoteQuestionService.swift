import Foundation
import Combine
import SwiftUI



// MARK: - ViewModels
class QuestionStoreViewModel: ObservableObject {
    @Published var featuredSets: [RemoteQuestionSet] = []
    @Published var popularSets: [RemoteQuestionSet] = []
    @Published var recentSets: [RemoteQuestionSet] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchResults: [RemoteQuestionSet] = []
    @Published var searchQuery = ""
    
    private let homeViewModel: HomeViewModel
    
    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
    }
}


struct QuestionSetCard: View {
   let set: RemoteQuestionSet
   let onDownload: () -> Void
   @Environment(\.colorScheme) private var colorScheme
   
   var body: some View {
       VStack(alignment: .leading, spacing: 16) {
           // 상단 영역
           HStack(alignment: .top) {
               // 아이콘
               Image(systemName: "book.fill")
                   .font(.system(size: 24))
                   .foregroundColor(.blue)
                   .frame(width: 40, height: 40)
                   .background(Color.blue.opacity(0.1))
                   .clipShape(Circle())
               
               VStack(alignment: .leading, spacing: 4) {
                   Text(set.title)
                       .font(.system(size: 18, weight: .semibold))
                       .foregroundColor(.primary)
                   
                   Text(set.description)
                       .font(.subheadline)
                       .foregroundColor(.secondary)
                       .lineLimit(2)
               }
           }
           
           Divider()
           
           // 하단 정보 영역
           HStack(spacing: 16) {
               // 문제 수
               HStack(spacing: 6) {
                   Image(systemName: "doc.text.fill")
                       .foregroundColor(.blue)
                   Text("\(set.questionCount) Questions")
                       .font(.system(size: 14, weight: .medium))
               }
               .foregroundColor(.secondary)
               
               // 난이도
               HStack(spacing: 6) {
                   Image(systemName: "chart.bar.fill")
                       .foregroundColor(.green)
                   Text(set.difficulty)
                       .font(.system(size: 14, weight: .medium))
               }
               .foregroundColor(.secondary)
               
               Spacer()
               
               // 다운로드 버튼
               Button(action: onDownload) {
                   HStack(spacing: 6) {
                       Image(systemName: "arrow.down.circle.fill")
                       Text("Download")
                   }
                   .font(.system(size: 14, weight: .medium))
                   .foregroundColor(.white)
                   .padding(.horizontal, 16)
                   .padding(.vertical, 8)
                   .background(Color.blue)
                   .cornerRadius(20)
               }
           }
       }
       .padding(16)
       .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
       .cornerRadius(16)
       .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
       .overlay(
           RoundedRectangle(cornerRadius: 16)
               .stroke(Color.gray.opacity(0.1), lineWidth: 1)
       )
       .padding(.horizontal)
   }
}

// Featured Section with carousel
struct FeaturedSection: View {
    let sets: [RemoteQuestionSet]
    let onDownload: (RemoteQuestionSet) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Featured")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(sets) { set in
                        FeaturedCard(set: set, onDownload: onDownload)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Featured Card
struct FeaturedCard: View {
    let set: RemoteQuestionSet
    let onDownload: (RemoteQuestionSet) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(set.title)
                    .font(.headline)
                
                Text(set.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(set.questionCount) questions", systemImage: "doc.text")
                    Spacer()
                    Button(action: { onDownload(set) }) {
                        Image(systemName: "arrow.down.circle.fill")
                            .imageScale(.large)
                    }
                }
                .font(.caption)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .frame(width: 280)
    }
}

// Category Section
struct CategorySection: View {
    let categories = ["Math", "Science", "Language", "History", "Geography", "General"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Categories")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(categories, id: \.self) { category in
                    CategoryCard(category: category)
                }
            }
        }
    }
}

// Category Card
struct CategoryCard: View {
    let category: String
    
    var body: some View {
        VStack {
            Image(systemName: iconName(for: category))
                .font(.title)
                .foregroundColor(.blue)
            Text(category)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func iconName(for category: String) -> String {
        switch category.lowercased() {
        case "math": return "function"
        case "science": return "flask.fill"
        case "language": return "textformat"
        case "history": return "clock.fill"
        case "geography": return "globe"
        default: return "book.fill"
        }
    }
}

// Question Set Section
struct QuestionSetSection: View {
    let title: String
    let sets: [RemoteQuestionSet]
    let onDownload: (RemoteQuestionSet) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(sets) { set in
                QuestionSetRow(set: set, onDownload: onDownload)
            }
        }
    }
}

// Question Set Row
struct QuestionSetRow: View {
    let set: RemoteQuestionSet
    let onDownload: (RemoteQuestionSet) -> Void
    
    var body: some View {
        HStack {
            
            VStack(alignment: .leading) {
                Text(set.title)
                    .font(.headline)
                Text("\(set.questionCount) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { onDownload(set) }) {
                Image(systemName: set.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                    .imageScale(.large)
                    .foregroundColor(set.isDownloaded ? .green : .blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
