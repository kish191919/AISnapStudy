// Views/Components/QuestionTypeCounter.swift
import SwiftUI

import SwiftUI

struct QuestionTypeCounter: View {
    let title: String
    @Binding var count: Int
    let maximum: Int = 10
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        count = max(0, count - 1)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .imageScale(.large)
                }
                .disabled(count <= 0)
                
                Text("\(count)")
                    .font(.headline)
                    .frame(width: 30)
                
                Button(action: {
                    withAnimation {
                        count = min(maximum, count + 1)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .imageScale(.large)
                }
                .disabled(count >= maximum)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}
