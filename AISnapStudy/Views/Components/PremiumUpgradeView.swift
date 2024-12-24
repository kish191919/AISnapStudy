import SwiftUI

struct PremiumUpgradeView: View {
    @StateObject private var storeService = StoreService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPlans = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Premium features section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Premium Features")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        FeatureRow(
                            icon: "sparkles",
                            title: "More Daily Questions",
                            description: "Create up to 30 question sets per day"
                        )
                        
                        FeatureRow(
                            icon: "square.and.arrow.down",
                            title: "Full Library Access",
                            description: "Download all question sets from our library"
                        )
                        
                        FeatureRow(
                            icon: "xmark.circle.fill",
                            title: "Ad-Free Experience",
                            description: "Enjoy learning without any advertisements"
                        )
                    }
                    .padding()
                    
                    // See Plans Button
                    Button {
                        showPlans = true
                    } label: {
                        Text("See Plans")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Premium Upgrade")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .sheet(isPresented: $showPlans) {
                SubscriptionPlansView()
            }
        }
    }
}

struct SubscriptionPlansView: View {
   @Environment(\.dismiss) private var dismiss
   @StateObject private var storeService = StoreService.shared
   @State private var showTerms = false
   @State private var selectedPlan: PlanType = .annual
   @State private var isLoading = false
   @State private var showAlert = false
   @State private var alertMessage = ""
   
   enum PlanType: String {
       case annual = "com.aisnapstudy.subscription.annual"
       case monthly = "com.aisnapstudy.subscription.monthly"
       
       var productId: String {
           return self.rawValue
       }
   }
   
   var body: some View {
       NavigationView {
           ScrollView {
               VStack(spacing: 24) {
                   Text("Choose your plan")
                       .font(.title2)
                       .fontWeight(.bold)
                   
                   // Annual Plan
                   PlanCard(
                       type: .annual,
                       title: "Annual",
                       price: "$99.99",
                       period: "/ year",
                       description: "Recurring billing.",
                       isSelected: selectedPlan == .annual,
                       discount: "45% off",
                       isBestValue: true,
                       action: { selectedPlan = .annual }
                   )
                   
                   // Monthly Plan
                   PlanCard(
                       type: .monthly,
                       title: "Monthly",
                       price: "$14.99",
                       period: "/ month",
                       description: "Recurring billing. Cancel anytime.",
                       isSelected: selectedPlan == .monthly,
                       action: { selectedPlan = .monthly }
                   )
                   
                   // How subscriptions work
                   SubscriptionInfoSection()
                   
                   // Terms and conditions link
                   Button("Terms and conditions") {
                       showTerms = true
                   }
                   .font(.footnote)
                   .foregroundColor(.blue)
                   
                   // Subscribe button
                   Button(action: {
                       Task {
                           await handlePurchase()
                       }
                   }) {
                       if isLoading {
                           ProgressView()
                               .progressViewStyle(CircularProgressViewStyle(tint: .white))
                       } else {
                           Text("Subscribe")
                               .font(.headline)
                               .foregroundColor(.white)
                       }
                   }
                   .frame(maxWidth: .infinity)
                   .padding()
                   .background(Color.yellow)
                   .cornerRadius(10)
                   .disabled(isLoading)
                   .padding(.horizontal)
               }
               .padding()
           }
           .navigationBarItems(leading: Button("Cancel") { dismiss() })
           .sheet(isPresented: $showTerms) {
               TermsAndConditionsView()
           }
           .alert("구매 오류", isPresented: $showAlert) {
               Button("확인", role: .cancel) { }
           } message: {
               Text(alertMessage)
           }
       }
       .task {
           // 상품 정보 로드
           await storeService.loadProducts()
       }
   }
   
   private func handlePurchase() async {
       isLoading = true
       defer { isLoading = false }
       
       do {
           if let product = storeService.products.first(where: { $0.id == selectedPlan.productId }) {
               try await storeService.purchase(product)
               await MainActor.run {
                   dismiss()
               }
           } else {
               throw PurchaseError.productNotFound
           }
       } catch {
           await MainActor.run {
               alertMessage = error.localizedDescription
               showAlert = true
           }
       }
   }
}


enum PurchaseError: LocalizedError {
    case noActiveAccount
    case verificationFailed
    case userCancelled
    case pending
    case unknown
    case productNotFound  // 추가된 case
    
    var errorDescription: String? {
        switch self {
        case .noActiveAccount:
            return "No active App Store account found. Please sign in to your Apple ID."
        case .verificationFailed:
            return "Unable to verify the purchase. Please try again."
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .unknown:
            return "An unknown error occurred."
        case .productNotFound:   // 에러 메시지 추가
            return "The selected product could not be found."
        }
    }
}

// StoreService의 PurchaseProduct enum 업데이트
enum PurchaseProduct: String, CaseIterable {
   case monthlySubscription = "com.aisnapstudy.subscription.monthly"
   case annualSubscription = "com.aisnapstudy.subscription.annual"
   
   var id: String { rawValue }
   var displayName: String {
       switch self {
       case .monthlySubscription:
           return "Monthly Subscription"
       case .annualSubscription:
           return "Annual Subscription"
       }
   }
}

struct TermsAndConditionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Payment will be charged to the user's iTunes Account upon confirmation of purchase.")
                        .padding(.bottom)
                    
                    Text("Subscription will renew automatically unless auto-renew is turned off at least 24 hours before the end of the current period.")
                        .padding(.bottom)
                    
                    Text("Account will be charged for renewal within 24 hours prior to the end of the current period and will identify the cost of the renewal.")
                        .padding(.bottom)
                    
                    Text("Subscriptions may be managed by the user and auto-renewal may be turned off in the user's account settings after purchase.")
                        .padding(.bottom)
                    
                    Text("Any unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription, where applicable.")
                        .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("Terms and conditions")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct PlanCard: View {
    let type: SubscriptionPlansView.PlanType
    let title: String
    let price: String
    let period: String
    let description: String
    let isSelected: Bool
    var discount: String? = nil
    var isBestValue: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if isBestValue {
                        Text("Best Value")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(alignment: .firstTextBaseline) {
                    Text(price)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(period)
                        .foregroundColor(.secondary)
                }
                
                if let discount = discount {
                    Text(discount)
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubscriptionInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How annual subscriptions work")
                .font(.headline)
            
            HStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.yellow)
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text("Today: Get instant access")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("You are billed for one year")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text("December 16, 2025: Renewal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Your subscription is renewed for another year unless you cancel before this date.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}


// View에서 사용할 수 있는 Premium 상태 표시 컴포넌트
struct SubscriptionStatusView: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    @State private var showUpgradeView = false
    
    var body: some View {
        HStack {
            Text(viewModel.subscriptionStatusText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !viewModel.isPremium {
                Button(action: {
                    showUpgradeView = true
                }) {
                    Text("Upgrade")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showUpgradeView) {
            PremiumUpgradeView()
        }
    }
}

