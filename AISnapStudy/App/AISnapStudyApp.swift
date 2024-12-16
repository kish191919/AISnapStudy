import SwiftUI
import CoreData

@main
struct AISnapStudyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isLoading = true

    
    init() {
        SecureArrayTransformer.register()
        setupAppearance()
        setupMetal()
    }

    var body: some Scene {
        WindowGroup {
            if isLoading {
                AnimatedSplashScreen()
                    .onAppear {
                        // 애니메이션 완료 후 메인 화면으로 전환
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isLoading = false
                            }
                        }
                    }
            } else {
                MainTabView()
                    .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
            }
        }
    }
    
    private func setupMetal() {
        // Metal 디바이스 체크
        guard MTLCreateSystemDefaultDevice() != nil else {
            print("Metal is not supported on this device")
            return
        }
        
        // MetalTools 프레임워크 초기화 지연
        DispatchQueue.main.async {
            // MetalTools 관련 작업
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setupCoreData()
        
        // OpenAI API Key 초기 설정
        Task {
            do {
                try await OpenAIService.shared.fetchAPIKey()
                print("✅ Successfully initialized OpenAI API Key")
            } catch {
                print("❌ Failed to fetch OpenAI API Key: \(error)")
            }
        }
        
        return true
    }
    
    // 앱 종료 시 API Key 정리
    func applicationWillTerminate(_ application: UIApplication) {
        OpenAIService.shared.cleanup()
    }
    
    private func setupCoreData() {
        let container = CoreDataService.shared.persistentContainer
        
        print("""
        📊 CoreData Configuration:
        • Store Descriptions: \(container.persistentStoreDescriptions.count)
        • View Context: \(container.viewContext)
        """)
        
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            print("❌ No store URL found")
            return
        }
        
        print("• Store URL: \(storeURL)")
        createCoreDataDirectoryIfNeeded(at: storeURL)
        setupCoreDataOptions(container: container)
    }
    
    private func createCoreDataDirectoryIfNeeded(at storeURL: URL) {
        let fileManager = FileManager.default
        let parentDirectory = storeURL.deletingLastPathComponent().path
        
        guard !fileManager.fileExists(atPath: parentDirectory) else { return }
        
        do {
            try fileManager.createDirectory(
                atPath: parentDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("✅ Created CoreData directory")
        } catch {
            print("❌ Failed to create CoreData directory: \(error)")
        }
    }
    
    private func setupCoreDataOptions(container: NSPersistentContainer) {
        // CoreData 옵션 설정
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 성능 최적화 설정
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.name = "MainContext"
    }
    
    // MARK: - Memory Management
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        CoreDataService.shared.viewContext.refreshAllObjects()
    }
}


struct AnimatedSplashScreen: View {
    @State private var isAnimating = false
    @State private var iconScale: CGFloat = 0.3
    @State private var titleOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 아이콘 애니메이션
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                
                // 앱 타이틀
                Text("AISnapStudy")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(titleOpacity)
                
                // 서브타이틀
                Text("Learn Smarter with AI")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(subtitleOpacity)
                
                // 로딩 인디케이터
                if isAnimating {
                    LoadingDots()
                        .frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.5)) {
                iconScale = 1.0
                isAnimating = true
            }
            
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                titleOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
                subtitleOpacity = 1.0
            }
        }
    }
}

// 로딩 닷 애니메이션
struct LoadingDots: View {
    @State private var animationStage = 0
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationStage == index ? 1.5 : 1)
                    .opacity(animationStage == index ? 1 : 0.5)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
                withAnimation(.spring()) {
                    animationStage = (animationStage + 1) % 3
                }
            }
        }
    }
}

// 앱 스타일 설정
extension AISnapStudyApp {
    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
