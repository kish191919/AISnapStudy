import Foundation
import Combine
import SwiftUI

class RemoteQuestionService {
    static let shared = RemoteQuestionService()
    private let baseURL = "https://aistockadvisor.net"
    private let cache = NSCache<NSString, NSArray>()
    
    func fetchFeaturedSets() async throws -> [RemoteQuestionSet] {
        let url = URL(string: "\(baseURL)/featured-sets")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([RemoteQuestionSet].self, from: data)
    }
    
    func fetchQuestionSet(_ id: String) async throws -> ProblemSet {
       print("🌐 Downloading question set with ID: \(id)")
       let url = URL(string: "\(baseURL)/api/question-sets/\(id)")!
       
       let (data, response) = try await URLSession.shared.data(from: url)
       
       guard let httpResponse = response as? HTTPURLResponse else {
           throw URLError(.badServerResponse)
       }
       
       print("📡 Response status: \(httpResponse.statusCode)")
       
       struct RemoteSet: Codable {
           let id: String
           let subject: String
           let subjectType: String
           let subjectId: String
           let subjectName: String
           let questions: [RemoteQuestion]
           let createdAt: String
           let educationLevel: String
           let name: String
           
           struct RemoteQuestion: Codable {
               let id: String
               let type: String
               let question: String
               let options: [String]
               let correctAnswer: String
               let explanation: String
               let hint: String
           }
       }
       
       let decoder = JSONDecoder()
       let remoteSet = try decoder.decode(RemoteSet.self, from: data)
       
       // Question 모델로 변환할 때 옵션 섞기 추가
       let questions = remoteSet.questions.map { q -> Question in
           let questionType: QuestionType = {
               switch q.type.lowercased() {
               case "multiple_choice":
                   return .multipleChoice
               case "true_false":
                   return .trueFalse
               default:
                   return .multipleChoice
               }
           }()
           
           // 객관식 문제의 보기 섞기
           let (shuffledOptions, correctAnswer) = questionType == .multipleChoice
               ? {
                   var options = q.options
                   options.shuffle()
                   let newCorrectIndex = options.firstIndex(of: q.correctAnswer) ?? 0
                   return (options, options[newCorrectIndex])
               }()
               : (q.options, q.correctAnswer)
               
           return Question(
               id: q.id,
               type: questionType,
               subject: DefaultSubject.download,
               question: q.question,
               options: shuffledOptions,
               correctAnswer: correctAnswer,
               explanation: q.explanation,
               hint: q.hint,
               isSaved: false,
               createdAt: Date()
           )
       }
       
       // ProblemSet으로 변환
       return ProblemSet(
           id: UUID().uuidString,
           subject: DefaultSubject.download,
           subjectType: "default",
           subjectId: DefaultSubject.download.rawValue,
           subjectName: "Downloaded Sets",
           questions: questions,
           createdAt: ISO8601DateFormatter().date(from: remoteSet.createdAt) ?? Date(),
           educationLevel: EducationLevel(rawValue: remoteSet.educationLevel) ?? .elementary,
           name: remoteSet.name
       )
    }
    
    func searchQuestionSets(query: String) async throws -> [RemoteQuestionSet] {
        let url = URL(string: "\(baseURL)/search?q=\(query)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([RemoteQuestionSet].self, from: data)
    }
    
    func fetchQuestionSets() async throws -> [RemoteQuestionSet] {
        print("🌐 Fetching remote question sets...")
        let url = URL(string: "\(baseURL)/api/question-sets")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        // 받은 JSON 데이터 출력
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Received JSON data: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // ISO8601 형식의 날짜 처리
        
        do {
            let sets = try decoder.decode([RemoteQuestionSet].self, from: data)
            print("✅ Fetched \(sets.count) remote sets")
            return sets
        } catch {
            print("🔴 Decoding error: \(error)")
            throw error
        }
    }

}

// MARK: - ViewModels
class QuestionStoreViewModel: ObservableObject {
    @Published var featuredSets: [RemoteQuestionSet] = []
    @Published var popularSets: [RemoteQuestionSet] = []
    @Published var recentSets: [RemoteQuestionSet] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchResults: [RemoteQuestionSet] = []
    @Published var searchQuery = ""
    
    private let remoteService = RemoteQuestionService.shared
    private let homeViewModel: HomeViewModel
    
    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
    }
    
    @MainActor
    func loadFeaturedSets() async {
        isLoading = true
        do {
            featuredSets = try await remoteService.fetchFeaturedSets()
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    @MainActor
    func downloadQuestionSet(_ set: RemoteQuestionSet) async {
        isLoading = true
        do {
            let problemSet = try await remoteService.fetchQuestionSet(set.id)
            // Convert to Download subject
            let downloadedSet = ProblemSet(
                subject: DefaultSubject.download,  // New Download subject
                subjectType: "default",
                subjectId: DefaultSubject.download.rawValue,
                subjectName: "Download",
                questions: problemSet.questions,
                createdAt: Date(),
                educationLevel: .high,  // Or determine from set.difficulty
                name: set.title
            )
            await homeViewModel.saveProblemSet(downloadedSet)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

// MARK: - Views
struct QuestionStoreView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var selectedCategory: String?
    @State private var showingSearch = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if homeViewModel.isLoadingRemote {
                    ProgressView("Loading question sets...")
                } else {
                    ForEach(homeViewModel.remoteSets) { remoteSet in
                        QuestionSetCard(
                            set: remoteSet,
                            onDownload: {
                                Task {
                                    await homeViewModel.downloadQuestionSet(remoteSet)
                                }
                            }
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Question Store")
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

extension RemoteQuestionService {
    private func handleNetworkError(_ error: Error) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                print("❌ No internet connection")
            case .timedOut:
                print("❌ Request timed out")
            case .cannotFindHost:
                print("❌ Cannot find host: \(urlError.failingURL?.host ?? "unknown")")
            default:
                print("❌ Network error: \(urlError.localizedDescription)")
            }
        } else {
            print("❌ Unknown error: \(error.localizedDescription)")
        }
    }
}
