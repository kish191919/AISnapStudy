
import SwiftUI

struct SpeedUpSection: View {
    @Binding var useTextExtraction: Bool 
    @State private var isExpanded: Bool = false
    @State private var showHelp = false
    
    var body: some View {
        VStack {
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Automatically extracts text from images to generate questions faster. Recommended when images contain mostly text.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 이미지 제한 설명 추가
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Image Selection Limits:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                                Text("• When enabled: Up to 3 images")
                                Text("• When disabled: Single image only")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                },
                label: {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("Speed Up")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $useTextExtraction)
                            .labelsHidden()
                        
                        Button(action: { showHelp = true }) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            )
        }
        .alert("Speed Up Mode", isPresented: $showHelp) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Speed Up mode allows batch processing of multiple images (up to 3) with text extraction. When disabled, you can process one image at a time for more detailed analysis.")
        }
    }
}
