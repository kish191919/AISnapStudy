
import SwiftUI

struct CustomNavigationBar: View {
    let title: String
    var subtitle: String? = nil
    var leadingButton: (() -> AnyView)? = nil
    var trailingButton: (() -> AnyView)? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                if let leading = leadingButton {
                    leading()
                }
                
                Spacer()
                
                VStack {
                    Text(title)
                        .font(.headline)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let trailing = trailingButton {
                    trailing()
                }
            }
            .padding()
            
            Divider()
        }
        .background(Color.white)
    }
}
