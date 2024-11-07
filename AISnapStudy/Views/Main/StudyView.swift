//  Views/Main/StudyView.swift

import SwiftUI

struct StudyView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var viewModel = StudyViewModel()
    
    var body: some View {
        NavigationView {
            if let problemSet = homeViewModel.selectedProblemSet {
                VStack {
                    // 현재 문제 표시
                    if let currentQuestion = viewModel.currentQuestion {
                        Group {
                            switch currentQuestion.type {
                            case .multipleChoice:
                                MultipleChoiceView(
                                    question: currentQuestion,
                                    selectedAnswer: $viewModel.selectedAnswer,
                                    showExplanation: viewModel.showExplanation
                                )
                                
                            case .fillInBlanks:
                                FillInBlanksView(
                                    question: currentQuestion,
                                    answer: $viewModel.selectedAnswer,
                                    showExplanation: viewModel.showExplanation
                                )
                                
                            case .matching:
                                MatchingView(
                                    question: currentQuestion,
                                    selectedPairs: $viewModel.matchingPairs,
                                    showExplanation: viewModel.showExplanation
                                )
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // 제출/다음 버튼
                        Button(action: {
                            if viewModel.showExplanation {
                                viewModel.nextQuestion()
                            } else {
                                viewModel.submitAnswer()
                            }
                        }) {
                            Text(viewModel.showExplanation ? "Next Question" : "Submit Answer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                        .disabled(!viewModel.canSubmit)
                        .padding()
                    }
                }
                .navigationTitle("Study")
                .onAppear {
                    viewModel.loadQuestions(problemSet.questions)
                }
            } else {
                VStack {
                    Text("No questions available")
                        .font(.headline)
                    Text("Create new questions from the Home screen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .navigationTitle("Study")
            }
        }
    }
}
