
import SwiftUI

struct MatchingView: View {
    let question: Question
    @Binding var selectedPairs: [String: String]
    let showExplanation: Bool
    let isCorrect: Bool?  // 추가
    
    // 드래그 관련 상태
    @State private var draggedItem: String?
    @State private var lines: [(from: String, to: String)] = []
    @State private var dragPosition: CGPoint = .zero
    @GestureState private var isDragging: Bool = false
    
    // 뷰의 좌표값을 저장
    @State private var itemPositions: [String: CGPoint] = [:]
    
    var body: some View {
        VStack(spacing: 30) {
            Text(question.question)
                .font(.headline)
                .padding(.bottom)
            
            HStack(spacing: 60) {
                // 왼쪽 컬럼 (문제)
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(question.options, id: \.self) { item in
                        Text(item)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(radius: 2)
                            )
                            .overlay(
                                GeometryReader { geo in
                                    Color.clear.onAppear {
                                        let frame = geo.frame(in: .global)
                                        itemPositions[item] = CGPoint(
                                            x: frame.maxX,
                                            y: frame.midY
                                        )
                                    }
                                }
                            )
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        if draggedItem == nil {
                                            draggedItem = item
                                        }
                                        dragPosition = gesture.location
                                    }
                                    .onEnded { gesture in
                                        if let dragged = draggedItem,
                                           let target = findTarget(at: gesture.location) {
                                            selectedPairs[dragged] = target
                                            lines.append((from: dragged, to: target))
                                        }
                                        draggedItem = nil
                                    }
                            )
                    }
                }
                
                // 연결선을 그리는 영역
                Canvas { context, size in
                    // 기존 연결선 그리기
                    for line in lines {
                        if let fromPoint = itemPositions[line.from],
                           let toPoint = itemPositions[line.to] {
                            let path = Path { p in
                                p.move(to: fromPoint)
                                p.addLine(to: toPoint)
                            }
                            context.stroke(path, with: .color(.blue), lineWidth: 2)
                        }
                    }
                    
                    // 현재 드래그 중인 선 그리기
                    if let dragged = draggedItem,
                       let startPoint = itemPositions[dragged] {
                        let path = Path { p in
                            p.move(to: startPoint)
                            p.addLine(to: dragPosition)
                        }
                        context.stroke(path, with: .color(.blue), lineWidth: 2)
                    }
                }
                .frame(width: 100)
                
                // 오른쪽 컬럼 (답)
                VStack(alignment: .trailing, spacing: 20) {
                    ForEach(question.matchingOptions, id: \.self) { item in
                        Text(item)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(radius: 2)
                            )
                            .overlay(
                                GeometryReader { geo in
                                    Color.clear.onAppear {
                                        let frame = geo.frame(in: .global)
                                        itemPositions[item] = CGPoint(
                                            x: frame.minX,
                                            y: frame.midY
                                        )
                                    }
                                }
                            )
                    }
                }
            }
            .padding()
            
            // 답안 제출 버튼
            if !showExplanation && selectedPairs.count == question.matchingOptions.count {
                Button(action: checkAnswer) {
                    Text("Submit Answer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding()
            }
            
            if showExplanation {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Explanation")
                        .font(.headline)
                    Text(question.explanation)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private func findTarget(at point: CGPoint) -> String? {
        for option in question.matchingOptions {
            if let position = itemPositions[option] {
                let distance = sqrt(
                    pow(point.x - position.x, 2) +
                    pow(point.y - position.y, 2)
                )
                if distance < 50 { // 50은 인식 반경
                    return option
                }
            }
        }
        return nil
    }
    
    private func checkAnswer() {
        // StudyViewModel에서 처리됨
    }
}
