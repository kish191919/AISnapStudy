import StoreKit

@MainActor
class StoreService: ObservableObject {
    static let shared = StoreService()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProducts: [Product] = []
    @Published private(set) var subscriptionStatus: UserSubscriptionStatus
    
    private let productIds: Set<String> = Set(PurchaseProduct.allCases.map { $0.id })
    private let defaults = UserDefaults.standard
    private let subscriptionStatusKey = "userSubscriptionStatus"
    private let lastResetDateKey = "lastResetDate"
    private var resetTimer: Timer?
    
    private init() {
        // 저장된 구독 상태 불러오기
        if let savedData = defaults.data(forKey: subscriptionStatusKey),
           let savedStatus = try? JSONDecoder().decode(UserSubscriptionStatus.self, from: savedData) {
            self.subscriptionStatus = savedStatus
        } else {
            self.subscriptionStatus = UserSubscriptionStatus.defaultStatus
        }
        
        // 초기화 시 상태 확인 및 리셋
        checkAndResetDailyQuestions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            await checkSubscriptionStatus()
        }
        
        setupDailyReset()
    }
    
    deinit {
        resetTimer?.invalidate()
    }
    
    private func setupDailyReset() {
        let calendar = Calendar.current
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let nextMidnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            return
        }
        
        resetTimer?.invalidate()
        resetTimer = Timer(fire: nextMidnight, interval: 86400, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAndResetDailyQuestions()
            }
        }
        
        if let timer = resetTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func checkAndResetDailyQuestions() {
        let calendar = Calendar.current
        let now = Date()
        
        let shouldReset = if let lastResetDate = defaults.object(forKey: lastResetDateKey) as? Date {
            !calendar.isDate(lastResetDate, inSameDayAs: now)
        } else {
            true
        }
        
        if shouldReset {
            resetDailyQuestions()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            await updatePurchasedProducts()
            await checkSubscriptionStatus()
            print("✅ Purchase successful")
            
        case .userCancelled:
            print("ℹ️ Purchase cancelled by user")
            
        case .pending:
            print("⏳ Purchase pending")
            
        @unknown default:
            print("❓ Unknown purchase result")
        }
    }
    
    func updatePurchasedProducts() async {
        purchasedProducts.removeAll()
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if let product = products.first(where: { $0.id == transaction.productID }) {
                purchasedProducts.append(product)
            }
        }
        
        await updateSubscriptionStatus()
    }
    
    private func updateSubscriptionStatus() async {
        let isPremium = !purchasedProducts.isEmpty
        subscriptionStatus.isPremium = isPremium
        
        // Premium 상태가 변경되었을 때만 질문 수 리셋
        if isPremium != subscriptionStatus.isPremium {
            resetDailyQuestions()
        }
        
        saveSubscriptionStatus()
    }
    
    private func resetDailyQuestions() {
        let maxQuestions = subscriptionStatus.isPremium ? 30 : 1
        subscriptionStatus.dailyQuestionsRemaining = maxQuestions
        subscriptionStatus.lastResetDate = Date()
        
        // 상태 저장
        saveSubscriptionStatus()
        // 마지막 리셋 날짜 저장
        defaults.set(Date(), forKey: lastResetDateKey)
    }
    
    func checkSubscriptionStatus() async {
        if let savedStatus = loadSubscriptionStatus() {
            if savedStatus.isPremium != subscriptionStatus.isPremium {
                // Premium 상태가 변경된 경우만 업데이트
                subscriptionStatus = savedStatus
                resetDailyQuestions()
            } else {
                // 그 외의 경우 남은 질문 수만 유지
                subscriptionStatus.dailyQuestionsRemaining = savedStatus.dailyQuestionsRemaining
            }
        }
        
        checkAndResetDailyQuestions()
    }
    
    func decrementRemainingQuestions() {
        guard subscriptionStatus.dailyQuestionsRemaining > 0 else { return }
        subscriptionStatus.dailyQuestionsRemaining -= 1
        saveSubscriptionStatus()
    }
    
    private func saveSubscriptionStatus() {
        if let encoded = try? JSONEncoder().encode(subscriptionStatus) {
            defaults.set(encoded, forKey: subscriptionStatusKey)
        }
    }
    
    private func loadSubscriptionStatus() -> UserSubscriptionStatus? {
        guard let data = defaults.data(forKey: subscriptionStatusKey),
              let status = try? JSONDecoder().decode(UserSubscriptionStatus.self, from: data) else {
            return nil
        }
        return status
    }
}
