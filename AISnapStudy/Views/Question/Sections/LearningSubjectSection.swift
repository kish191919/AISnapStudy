import SwiftUI

struct LearningSubjectSection: View {
   @Binding var selectedSubject: Subject
   
   let columns = [
       GridItem(.flexible()),
       GridItem(.flexible()),
       GridItem(.flexible())
   ]
   
   var body: some View {
       LazyVGrid(columns: columns, spacing: 12) {
           ForEach(Subject.allCases, id: \.self) { subject in
               SubjectSelectionButton(
                   subject: subject,
                   isSelected: selectedSubject == subject
               ) {
                   withAnimation(.spring()) {
                       selectedSubject = subject
                   }
               }
           }
       }
       .padding(.vertical, 8)
   }
}

