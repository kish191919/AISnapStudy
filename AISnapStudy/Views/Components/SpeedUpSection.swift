
import SwiftUI

struct SpeedUpSection: View {
    @Binding var useTextExtraction: Bool
    @State private var isExpanded: Bool = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                Text("Automatically extracts text from images to generate questions faster. Recommended when images contain mostly text.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                }
            }
        )
    }
}
