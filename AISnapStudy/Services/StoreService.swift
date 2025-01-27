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
        
        // 트랜잭션 업데이트 리스너 추가
        Task {
            // 시작 시 트랜잭션 업데이트 확인
            for await result in Transaction.updates {
                do {
                    guard let transaction = try? result.payloadValue else {
                        throw PurchaseError.verificationFailed
                    }
                    await handleVerifiedTransaction(transaction)
                } catch {
                    print("❌ Transaction failed verification: \(error)")
                }
            }
        }
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            await checkSubscriptionStatus()
        }
        
        setupDailyReset()
    }

    // 새로운 트랜잭션 처리 메서드
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        // 구독 상태 업데이트
        subscriptionStatus.isPremium = true
        resetDailyQuestions() // 프리미엄 상태에 맞게 일일 질문 수 리셋
        
        // 상태 저장
        saveSubscriptionStatus()
        
        // 트랜잭션 완료 처리
        await transaction.finish()
        
        print("✅ Transaction processed successfully - Premium status updated")
    }

    
    
    
    deinit {
        resetTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func canDownloadMoreSets() -> Bool {
        return subscriptionStatus.isPremium || subscriptionStatus.downloadedSetsCount < UserSubscriptionStatus.maxFreeDownloads
    }
    
    func incrementDownloadCount() {
        guard !subscriptionStatus.isPremium else { return }
        subscriptionStatus.downloadedSetsCount += 1
        saveSubscriptionStatus()
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
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                guard let transaction = try? verification.payloadValue else {
                    throw PurchaseError.verificationFailed
                }
                
                // 구독 상태 즉시 업데이트
                subscriptionStatus.isPremium = true
                resetDailyQuestions() // 프리미엄 상태로 일일 질문 수 리셋
                saveSubscriptionStatus()
                
                await transaction.finish()
                
                // UI 업데이트를 위해 구매 상태 갱신
                await updatePurchasedProducts()
                await checkSubscriptionStatus()
                
                print("✅ Purchase successful - Premium status activated")
                
            case .userCancelled:
                throw PurchaseError.userCancelled
            case .pending:
                throw PurchaseError.pending
            @unknown default:
                throw PurchaseError.unknown
            }
        } catch {
            print("🚫 Purchase failed: \(error.localizedDescription)")
            throw error
        }
    }

    private func resetDailyQuestions() {
        // 프리미엄 상태에 따라 적절한 일일 질문 수 설정
        let maxQuestions = subscriptionStatus.isPremium ? 30 : 2
        subscriptionStatus.dailyQuestionsRemaining = maxQuestions
        subscriptionStatus.lastResetDate = Date()
        
        saveSubscriptionStatus()
        defaults.set(Date(), forKey: lastResetDateKey)
        
        print("🔄 Daily questions reset - Premium: \(subscriptionStatus.isPremium), Questions: \(maxQuestions)")
    }

    private func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        // 현재 활성화된 구독 확인
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            // 구독 상품 확인
            if let product = products.first(where: { $0.id == transaction.productID }) {
                hasActiveSubscription = true
                purchasedProducts.append(product)
            }
        }
        
        // 구독 상태 업데이트
        let wasPremium = subscriptionStatus.isPremium
        subscriptionStatus.isPremium = hasActiveSubscription
        
        // 프리미엄 상태가 변경되었다면 질문 수 리셋
        if wasPremium != hasActiveSubscription {
            resetDailyQuestions()
        }
        
        saveSubscriptionStatus()
        print("📱 Subscription status updated - Premium: \(hasActiveSubscription)")
    }
    
    func decrementRemainingQuestions() {
        guard subscriptionStatus.dailyQuestionsRemaining > 0 else { return }
        subscriptionStatus.dailyQuestionsRemaining -= 1
        saveSubscriptionStatus()
    }
    
    // MARK: - Private Methods
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
    
    private func updatePurchasedProducts() async {
        purchasedProducts.removeAll()
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if let product = products.first(where: { $0.id == transaction.productID }) {
                purchasedProducts.append(product)
            }
        }
        
        await updateSubscriptionStatus()
    }
    
    private func checkSubscriptionStatus() async {
        if let savedStatus = loadSubscriptionStatus() {
            if savedStatus.isPremium != subscriptionStatus.isPremium {
                subscriptionStatus = savedStatus
                resetDailyQuestions()
            } else {
                subscriptionStatus.dailyQuestionsRemaining = savedStatus.dailyQuestionsRemaining
            }
        }
        
        checkAndResetDailyQuestions()
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
