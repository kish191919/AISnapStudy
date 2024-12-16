
import Foundation


struct UserSubscriptionStatus: Codable {
    var isPremium: Bool
    var dailyQuestionsRemaining: Int
    var lastResetDate: Date?
    
    static let defaultStatus = UserSubscriptionStatus(
        isPremium: false,
        dailyQuestionsRemaining: 1,
        lastResetDate: nil
    )
}
