
//  Views/Components/HistoryCard.swift

import SwiftUI

struct HistoryCard: View {
    let session: StudySession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.problemSet.title)
                    .font(.headline)
                Spacer()
                
                Text(session.problemSet.subject.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(session.problemSet.subject.color.opacity(0.2))
                    .foregroundColor(session.problemSet.subject.color)
                    .cornerRadius(4)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.score ?? 0)%")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(session.duration?.formatted ?? "N/A")
                        .font(.subheadline)
                }
            }
            
            HStack {
                Text("Questions: \(session.answers.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Helper extension for time formatting
private extension TimeInterval {
    var formatted: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
