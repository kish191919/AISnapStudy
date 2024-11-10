// Views/Components/QuestionTypeCounter.swift
import SwiftUI


import SwiftUI

struct QuestionTypeCounter: View {
    let title: String
    @Binding var count: Int
    let maximum: Int = 10
    
    // 각 버튼에 대한 별도의 액션 정의
    private func incrementCount() {
        if count < maximum {
            count += 1
            print("\(title): Increased to \(count)")
        }
    }
    
    private func decrementCount() {
        if count > 0 {
            count -= 1
            print("\(title): Decreased to \(count)")
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 16) {
                // Decrease Button
                Button {
                    decrementCount()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle()) // 중요: 버튼 스타일 분리
                .disabled(count <= 0)
                
                Text("\(count)")
                    .font(.headline)
                    .frame(width: 30)
                
                // Increase Button
                Button {
                    incrementCount()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle()) // 중요: 버튼 스타일 분리
                .disabled(count >= maximum)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}
