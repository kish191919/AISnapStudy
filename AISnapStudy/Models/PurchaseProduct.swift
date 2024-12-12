
import Foundation


enum PurchaseProduct: String, CaseIterable {
    case premiumUpgrade = "com.aisnapstudy.premiumupgrade"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .premiumUpgrade:
            return "Premium Upgrade"
        }
    }
}

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
