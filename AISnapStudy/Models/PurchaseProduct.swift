
import Foundation


struct UserSubscriptionStatus: Codable {
    var isPremium: Bool
    var dailyQuestionsRemaining: Int
    var downloadedSetsCount: Int  // 추가: 다운로드한 세트 수 추적
    var lastResetDate: Date?
    
    static let defaultStatus = UserSubscriptionStatus(
        isPremium: false,
        dailyQuestionsRemaining: 1,
        downloadedSetsCount: 0,  // 초기값 0
        lastResetDate: nil
    )
    
    static let maxFreeDownloads = 5  // 무료 사용자의 최대 다운로드 수
}
