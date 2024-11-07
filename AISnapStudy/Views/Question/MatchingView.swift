// Views/Question/MatchingView.swift
import SwiftUI
import UniformTypeIdentifiers

struct MatchingDropDelegate: DropDelegate {
    let item: String
    @Binding var selectedPairs: [String: String]
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [UTType.text.identifier]).first else {
            return false
        }
        
        itemProvider.loadObject(ofClass: NSString.self) { string, error in
            guard let droppedString = string as? String, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                // Remove any existing pairs with this dropped string
                if let existingKey = selectedPairs.first(where: { $0.value == droppedString })?.key {
                    selectedPairs.removeValue(forKey: existingKey)
                }
                selectedPairs[item] = droppedString
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Optional: Add visual feedback when drag enters
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [UTType.text.identifier])
    }
}

struct MatchingView: View {
    let question: Question
    @Binding var selectedPairs: [String: String]
    let showExplanation: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text(question.question)
                .font(.headline)
                .padding(.bottom)
            
            HStack(spacing: 20) {
                // Left Column (Items to match from)
                VStack(spacing: 12) {
                    ForEach(question.options, id: \.self) { item in
                        Text(item)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondaryBackground)
                            .cornerRadius(8)
                            .onDrag {
                                NSItemProvider(object: item as NSString)
                            }
                    }
                }
                
                // Right Column (Items to match to)
                VStack(spacing: 12) {
                    ForEach(question.matchingOptions, id: \.self) { item in
                        Text(selectedPairs[item] ?? "Drop here")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondaryBackground)
                            .cornerRadius(8)
                            .onDrop(of: [.text], delegate: MatchingDropDelegate(
                                item: item,
                                selectedPairs: $selectedPairs
                            ))
                    }
                }
            }
        }
        .padding()
        .disabled(showExplanation)
    }
}
