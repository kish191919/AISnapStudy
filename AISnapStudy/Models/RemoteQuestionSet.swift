import Foundation

// MARK: - Models
struct RemoteQuestionSet: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let difficulty: String
    let questionCount: Int
    let downloadCount: Int
    let createdAt: Date
    let updatedAt: Date
    var isDownloaded: Bool = false  // 기본값 설정
    
    // CodingKeys를 명시적으로 정의하여 isDownloaded를 디코딩에서 제외
    private enum CodingKeys: String, CodingKey {
        case id, title, description, category
        case difficulty, questionCount, downloadCount
        case createdAt, updatedAt
        // isDownloaded는 CodingKeys에서 제외
    }
}
