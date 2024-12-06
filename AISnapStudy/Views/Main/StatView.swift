import SwiftUI
import Charts
import CoreData


struct StatView: View {
   @ObservedObject var viewModel: StatViewModel
   @Binding var selectedTab: Int
   let correctAnswers: Int
   let totalQuestions: Int
   
   var incorrectAnswers: Int {
       totalQuestions - correctAnswers
   }
   
   var percentageCorrect: Int {
       guard totalQuestions > 0 else { return 0 }
       return Int((Double(correctAnswers) / Double(totalQuestions)) * 100)
   }
   
   var body: some View {
       ScrollView {
           VStack(spacing: 20) {
               Text("Result")
                   .font(.title)
                   .padding(.top)
               
               // Progress Circle
               ZStack {
                   Circle()
                       .trim(from: 0, to: 1)
                       .stroke(Color.orange, lineWidth: 25)
                       .rotationEffect(.degrees(-90))
                       .frame(width: 200, height: 200)
                   
                   Circle()
                       .trim(from: 0, to: Double(correctAnswers) / Double(totalQuestions))
                       .stroke(Color.green, lineWidth: 25)
                       .rotationEffect(.degrees(-90))
                       .frame(width: 200, height: 200)
                   
                   Text("\(percentageCorrect)%")
                       .font(.system(size: 40, weight: .bold))
               }
               .padding(.vertical)
               
               // Correct/Incorrect Labels
               HStack(spacing: 50) {
                   HStack {
                       Text("Correct")
                           .foregroundColor(.green)
                       Text("\(correctAnswers)")
                           .font(.headline)
                           .padding(8)
                           .background(
                               Circle()
                                   .fill(Color.green.opacity(0.2))
                           )
                   }
                   
                   HStack {
                       Text("Incorrect")
                           .foregroundColor(.orange)
                       Text("\(incorrectAnswers)")
                           .font(.headline)
                           .padding(8)
                           .background(
                               Circle()
                                   .fill(Color.orange.opacity(0.2))
                           )
                   }
               }
               
               Spacer()
               
               VStack(spacing: 12) {
                   Button(action: {
                       viewModel.resetProgress()
                       viewModel.logCurrentQuestionState()
                       withAnimation {
                           selectedTab = 1
                       }
                   }) {
                       Text("Retry Test")
                           .font(.headline)
                           .foregroundColor(.white)
                           .padding()
                           .frame(maxWidth: .infinity)
                           .background(Color.blue)
                           .cornerRadius(10)
                   }
                   
                   Button(action: {
                       withAnimation {
                           selectedTab = 2  // Review 탭으로 이동
                       }
                   }) {
                       Text("Take New Test")
                           .font(.headline)
                           .foregroundColor(.white)
                           .padding()
                           .frame(maxWidth: .infinity)
                           .background(Color.green)
                           .cornerRadius(10)
                   }
               }
               .padding(.horizontal)
               .padding(.bottom, 20)
           }
       }
   }
}
