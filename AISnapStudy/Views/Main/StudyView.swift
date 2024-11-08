//  Views/Main/StudyView.swift

import SwiftUI

import SwiftUI

struct StudyView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var viewModel = StudyViewModel()
    
    var body: some View {
        NavigationView {
            if let problemSet = homeViewModel.selectedProblemSet {
                VStack {
                    // Progress Indicator
                    ProgressView(value: viewModel.questionProgress)
                        .progressViewStyle(.linear)
                        .padding()
                    
                    Text(viewModel.progress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
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
                            
                            // Explanation View when shown
                            if viewModel.showExplanation {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Explanation")
                                        .font(.headline)
                                    Text(currentQuestion.explanation)
                                        .font(.body)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .padding()
                            }
                        }
                        .padding()
                        .onAppear {
                            debugPrint("Question view appeared")
                        }
                        
                        Spacer()
                        
                        // Submit/Next Button
                        Button(action: {
                            if viewModel.showExplanation {
                                if viewModel.isLastQuestion {
                                    // Save progress and return
                                    viewModel.saveProgress()
                                    homeViewModel.clearSelectedProblemSet()
                                } else {
                                    viewModel.nextQuestion()
                                }
                            } else {
                                viewModel.submitAnswer()
                            }
                        }) {
                            Text(viewModel.showExplanation ?
                                (viewModel.isLastQuestion ? "Finish" : "Next Question") :
                                "Submit Answer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.canSubmit ? Color.accentColor : Color.gray)
                                .cornerRadius(10)
                        }
                        .disabled(!viewModel.canSubmit)
                        .padding()
                        
                    } else {
                        Text("No questions loaded")
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Study")
                .onAppear {
                    debugPrint("StudyView appeared with problem set: \(problemSet.id)")
                    debugPrint("Questions count: \(problemSet.questionCount)")
                    viewModel.loadQuestions(problemSet.questions)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No questions available")
                        .font(.headline)
                    
                    Text("Create new questions from the Home screen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .navigationTitle("Study")
                .onAppear {
                    debugPrint("StudyView - No problem set selected")
                }
            }
        }
    }
}
