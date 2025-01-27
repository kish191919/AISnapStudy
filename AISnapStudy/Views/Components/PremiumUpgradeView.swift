import SwiftUI

struct PremiumUpgradeView: View {
    @StateObject private var storeService = StoreService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPlans = false
    
    var body: some View {
        NavigationStack {  // NavigationView를 NavigationStack으로 변경
            ScrollView {
                VStack(spacing: 20) {
                    // Premium features section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Premium Features")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // iPad에 맞게 Grid 레이아웃 적용
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 300, maximum: 500))
                        ], spacing: 16) {
                            
                            FeatureRow(
                               icon: "calendar.badge.plus",
                               title: "More Daily Questions",
                               description: "Create up to 30 question sets per day"
                            )
                            
                            FeatureRow(
                                icon: "xmark.circle.fill",
                                title: "Ad-Free Experience",
                                description: "Enjoy learning without any advertisements"
                            )

                        }
                        .padding(.horizontal)
                    }
                    
                    // See Plans Button
                    Button {
                        showPlans = true
                    } label: {
                        Text("See Plans")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: min(UIScreen.main.bounds.width - 40, 400))
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Premium Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showPlans) {
            SubscriptionPlansView()
        }
    }
}

struct SubscriptionPlansView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Choose your plan")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // LazyVGrid 대신 조건부 레이아웃 사용
                    if horizontalSizeClass == .regular {
                        // 아이패드용 레이아웃 - 나란히 배치
                        HStack(spacing: 20) {
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
                        }
                    } else {
                        // 핸드폰용 레이아웃 - 세로로 배치
                        VStack(spacing: 12) { // 간격 축소
                            // Annual Plan - 높이 줄임
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
                            .frame(height: 150) // 고정 높이 설정
                            
                            // Monthly Plan - 높이 줄임
                            PlanCard(
                                type: .monthly,
                                title: "Monthly",
                                price: "$14.99",
                                period: "/ month",
                                description: "Recurring billing. Cancel anytime.",
                                isSelected: selectedPlan == .monthly,
                                action: { selectedPlan = .monthly }
                            )
                            .frame(height: 150) // 고정 높이 설정
                        }
                    }
                    
                    // Subscription Info with adjusted width
                    SubscriptionInfoSection(selectedPlan: selectedPlan)
                        .frame(maxWidth: 600)
                    
                    // Terms and Subscribe buttons
                    VStack(spacing: 16) {
                        Button("Terms and conditions") {
                            showTerms = true
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                        
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
                        .frame(maxWidth: min(UIScreen.main.bounds.width - 40, 400))
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(10)
                        .disabled(isLoading)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsAndConditionsView()
        }
        .alert("Purchase Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .task {
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
            VStack(alignment: .leading, spacing: 8) {
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
                
                HStack(alignment: .center, spacing: 8) {  // 여기를 수정
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let discount = discount {
                        Text(discount)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text(price)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(period)
                        .foregroundColor(.secondary)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer() // 남은 공간을 채워서 높이를 동일하게 만듭니다
            }
            .padding(12)
            .frame(maxWidth: .infinity) // 최소 높이를 지정하여 카드 크기를 통일
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
    let selectedPlan: SubscriptionPlansView.PlanType  // 선택된 플랜 전달받기
    
    private var renewalDate: Date {
        let calendar = Calendar.current
        let today = Date()
        
        // 선택된 플랜에 따라 갱신 기간 설정
        switch selectedPlan {
        case .annual:
            return calendar.date(byAdding: .year, value: 1, to: today) ?? today
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: today) ?? today
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How \(selectedPlan == .annual ? "annual" : "monthly") subscriptions work")
                .font(.headline)
            
            HStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.yellow)
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text("Today: Get instant access")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("You are billed for one \(selectedPlan == .annual ? "year" : "month")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text("\(dateFormatter.string(from: renewalDate)): Renewal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Your subscription is renewed for another \(selectedPlan == .annual ? "year" : "month") unless you cancel before this date.")
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
       HStack(alignment: .top, spacing: 12) {
           Image(systemName: icon)
               .font(.title2)
               .foregroundColor(.blue)
               .frame(width: 24)
               
           VStack(alignment: .leading, spacing: 4) {
               Text(title)
                   .font(.headline)
                   .frame(maxWidth: .infinity, alignment: .leading)
               Text(description)
                   .font(.subheadline)
                   .foregroundColor(.secondary)
                   .frame(maxWidth: .infinity, alignment: .leading)
           }
       }
       .frame(maxWidth: .infinity, alignment: .leading)
       .padding(.horizontal)
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

