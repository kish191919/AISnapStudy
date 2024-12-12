import SwiftUI

struct PremiumUpgradeView: View {
    @StateObject private var storeService = StoreService.shared
    @Environment(\.dismiss) private var dismiss
    
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
                        
                        // Add more premium features here
                    }
                    .padding()
                    
                    // Purchase button
                    if let product = storeService.products.first {
                        Button {
                            Task {
                                try? await storeService.purchase(product)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Text("Upgrade Now")
                                Text(product.displayPrice)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Premium Upgrade")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
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
