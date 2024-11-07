
// ViewModels/HomeViewModel.swift
import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published private(set) var problemSets: [ProblemSet] = []
    @Published private(set) var savedQuestions: [Question] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var selectedProblemSet: ProblemSet?

    func setSelectedProblemSet(_ problemSet: ProblemSet?) {
        self.selectedProblemSet = problemSet
    }

    func clearSelectedProblemSet() {
        self.selectedProblemSet = nil
    }
   
   private let storageService: StorageService
   private var cancellables = Set<AnyCancellable>()
   
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
        Task {
            await loadData()
        }
    }

    @MainActor
    func loadData() {
        isLoading = true
        
        do {
            // Load problem sets and saved questions
            problemSets = try storageService.getProblemSets()
            savedQuestions = try storageService.getSavedQuestions()
            
            // Select the most recently created problem set
            selectedProblemSet = problemSets.first
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
   
   func deleteProblemSet(_ problemSet: ProblemSet) {
       guard let index = problemSets.firstIndex(where: { $0.id == problemSet.id }) else {
           return
       }
       
       let deletedProblemSet = problemSets.remove(at: index)
       
       Task {
           do {
               try await Task.detached {
                   var sets = try self.storageService.getProblemSets()
                   sets.removeAll { $0.id == problemSet.id }
                   try self.storageService.saveProblemSets(sets)
               }.value
           } catch {
               await MainActor.run {
                   self.error = error
                   // Revert deletion if storage update fails
                   self.problemSets.insert(deletedProblemSet, at: index)
               }
           }
       }
   }
   
   func deleteQuestion(_ question: Question) {
       guard let index = savedQuestions.firstIndex(where: { $0.id == question.id }) else {
           return
       }
       
       let deletedQuestion = savedQuestions.remove(at: index)
       
       Task {
           do {
               try await Task.detached {
                   var questions = try self.storageService.getSavedQuestions()
                   questions.removeAll { $0.id == question.id }
                   try self.storageService.saveQuestions(questions)
               }.value
           } catch {
               await MainActor.run {
                   self.error = error
                   // Revert deletion if storage update fails
                   self.savedQuestions.insert(deletedQuestion, at: index)
               }
           }
       }
   }
   
   func saveProblemSet(_ problemSet: ProblemSet) {
       Task {
           do {
               try await Task.detached {
                   try self.storageService.saveProblemSet(problemSet)
               }.value
               
               await MainActor.run {
                   self.problemSets.append(problemSet)
                   // Update selected problem set to the newly created one
                   self.selectedProblemSet = problemSet
               }
           } catch {
               await MainActor.run {
                   self.error = error
               }
           }
       }
   }
   
   func saveQuestion(_ question: Question) {
       Task {
           do {
               try await Task.detached {
                   try self.storageService.saveQuestion(question)
               }.value
               
               await MainActor.run {
                   self.savedQuestions.append(question)
               }
           } catch {
               await MainActor.run {
                   self.error = error
               }
           }
       }
   }
   
   // Method to update selected problem set
    func selectProblemSet(_ problemSet: ProblemSet?) {
        if let problemSet = problemSet {
            self.selectedProblemSet = problemSet
        } else {
            self.selectedProblemSet = nil
        }
    }
}
