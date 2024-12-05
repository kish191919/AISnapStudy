import SwiftUI



struct ReviewView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @ObservedObject var viewModel: ReviewViewModel
    @StateObject private var subjectManager = SubjectManager.shared
    @State private var showSubjectManagement = false
    @State private var searchText = ""
    @State private var selectedSubject: SubjectType?
    @Binding var selectedTab: Int  // 새로 추가
   
    // 초기화 구문 수정
    public init(viewModel: ReviewViewModel, selectedTab: Binding<Int>) {
        self.viewModel = viewModel
        self._selectedTab = selectedTab
    }
    
    private var visibleSubjects: [SubjectType] {
        let defaultSubjects = DefaultSubject.allCases.filter { !subjectManager.isDeleted($0) }
        let customSubjects = subjectManager.customSubjects.filter { $0.isActive }
        
        let subjects = defaultSubjects as [SubjectType] + customSubjects
        
        print("""
        📚 ReviewView - Visible Subjects:
        • Total Subjects: \(subjects.count)
        • Active Default Subjects: \(defaultSubjects.map { $0.displayName })
        • Active Custom Subjects: \(customSubjects.map { $0.displayName })
        • Hidden Subjects: \(subjectManager.hiddenDefaultSubjects)
        """)
        
        return subjects
    }
   
   private var allSubjects: [SubjectType] {
       var subjects: [SubjectType] = []
       
       let activeDefaultSubjects = DefaultSubject.allCases.filter { !subjectManager.isDeleted($0) }
       subjects.append(contentsOf: activeDefaultSubjects)
       
       let activeCustomSubjects = subjectManager.customSubjects.filter { $0.isActive }
       subjects.append(contentsOf: activeCustomSubjects)
       
       print("📚 Review - Active Default Subjects: \(activeDefaultSubjects.map { $0.displayName })")
       print("📚 Review - Active Custom Subjects: \(activeCustomSubjects.map { $0.displayName })")
       print("🔒 Review - Hidden Subjects: \(subjectManager.hiddenDefaultSubjects)")
       
       return subjects
   }
   
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 5) {
                    // 상단 여백 추가
                    Spacer()
                        .frame(height: 5)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 5) {
                        ForEach(visibleSubjects, id: \.id) { subject in
                            NavigationLink(
                                destination: ProblemSetsListView(
                                    subject: subject,
                                    problemSets: filterProblemSets(subject: subject),
                                    selectedTab: $selectedTab
                                )
                            ) {
                                SubjectCardView(
                                    subject: subject,
                                    problemSetCount: filterProblemSets(subject: subject).count
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Review")
                        .font(.title)
                        .padding(.bottom, 5)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSubjectManagement = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showSubjectManagement) {
                NavigationView {
                    SubjectManagementView()
                        .navigationTitle("Manage Subjects")
                        .navigationBarItems(
                            trailing: Button("Done") {
                                showSubjectManagement = false
                            }
                        )
                }
            }
        }
    }    // 필터링 함수 수정
    private func filterProblemSets(subject: SubjectType) -> [ProblemSet] {
        return homeViewModel.problemSets.filter { problemSet in
            if let defaultSubject = subject as? DefaultSubject {
                return problemSet.subjectType == "default" &&
                       problemSet.subject.rawValue == defaultSubject.rawValue
            } else if let customSubject = subject as? CustomSubject {
                return problemSet.subjectType == "custom" &&
                       problemSet.subjectId == customSubject.id
            }
            return false
        }
    }
}

struct SubjectCardView: View {
   let subject: SubjectType
   let problemSetCount: Int
   
   var body: some View {
       VStack(spacing: 12) {
           Image(systemName: subject.icon)
               .font(.system(size: 32))
               .foregroundColor(subject.color)
           
           Text(subject.displayName)
               .font(.headline)
               .foregroundColor(.primary)
               .lineLimit(1)
           
           Text("\(problemSetCount) sets")
               .font(.caption)
               .foregroundColor(.secondary)
       }
       .frame(maxWidth: .infinity)
       .padding(.vertical, 24)
       .background(
           RoundedRectangle(cornerRadius: 16)
               .fill(subject.color.opacity(0.1))
               .overlay(
                   RoundedRectangle(cornerRadius: 16)
                       .stroke(subject.color.opacity(0.2), lineWidth: 1)
               )
       )
       .contentShape(Rectangle())
   }
}

// SavedQuestionsRow 컴포넌트 분리
struct SavedQuestionsRow: View {
    let savedQuestions: [Question]
    let homeViewModel: HomeViewModel
    
    var body: some View {
        NavigationLink(
            destination: SavedQuestionsView(
                questions: savedQuestions,
                homeViewModel: homeViewModel
            )
        ) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.blue)
                Text("Saved Questions")
                    .font(.headline)
                Spacer()
                Text("\(savedQuestions.count)")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// SubjectRow 컴포넌트 분리
struct SubjectListRow: View {
    let subject: SubjectType
    let problemSets: [ProblemSet]
    let subjectManager: SubjectManager  // SubjectManager 인스턴스 필요
    @Binding var selectedTab: Int  // 추가
    
    var body: some View {
        if !subjectManager.isDeleted(subject.id) {
            NavigationLink(
                destination: ProblemSetsListView(
                    subject: subject,
                    problemSets: filterProblemSets(subject: subject, problemSets: problemSets),
                    selectedTab: $selectedTab  // 추가
                )
            ) {
                HStack {
                    Image(systemName: subject.icon)
                        .foregroundColor(subject.color)
                    // 여기를 수정 - subject.displayName 대신 subjectManager.getDisplayName 사용
                    if let defaultSubject = subject as? DefaultSubject {
                        Text(subjectManager.getDisplayName(for: defaultSubject))
                    } else {
                        Text(subject.displayName)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
        }
    }
    
    private func filterProblemSets(subject: SubjectType, problemSets: [ProblemSet]) -> [ProblemSet] {
        return problemSets.filter { problemSet in
            if let defaultSubject = subject as? DefaultSubject {
                return problemSet.subjectType == "default" &&
                       problemSet.subject.rawValue == defaultSubject.rawValue
            } else if let customSubject = subject as? CustomSubject {
                return problemSet.subjectType == "custom" &&
                       problemSet.subjectId == customSubject.id
            }
            return false
        }
    }
}
// ReviewView용 DefaultSubjectsSection 컴포넌트
struct ReviewDefaultSubjectsSection: View {
    @ObservedObject var subjectManager: SubjectManager
    let problemSets: [ProblemSet]
    @ObservedObject var homeViewModel: HomeViewModel
    @Binding var selectedTab: Int  // 추가
    
    var body: some View {
        Section(header: Text("Default Subjects")) {
            ForEach(DefaultSubject.allCases, id: \.id) { subject in
                let filteredSets = problemSets.filter {
                    $0.subjectType == "default" &&
                    $0.subject.rawValue == subject.rawValue
                }.sorted(by: { $0.createdAt > $1.createdAt })
                
                NavigationLink(
                    destination: ProblemSetsListView(
                        subject: subject,
                        problemSets: filteredSets,
                        selectedTab: $selectedTab  // 추가
                    )
                ) {
                    SubjectRow(subject: subject)
                }
            }
        }
    }
}

// ReviewView용 CustomSubjectsSection 컴포넌트
struct ReviewCustomSubjectsSection: View {
    @ObservedObject var subjectManager: SubjectManager
    let problemSets: [ProblemSet]
    @ObservedObject var homeViewModel: HomeViewModel
    @Binding var selectedTab: Int  // 추가
    
    var body: some View {
        Section(header: Text("Custom Subjects")) {
            ForEach(subjectManager.customSubjects.filter { $0.isActive }) { subject in
                let filteredSets = problemSets.filter { $0.subject.displayName == subject.displayName }
                    .sorted(by: { $0.createdAt > $1.createdAt })
                
                NavigationLink(
                    destination: ProblemSetsListView(
                        subject: subject,
                        problemSets: filteredSets,
                        selectedTab: $selectedTab  // 추가
                    )
                ) {
                    SubjectRow(subject: subject)
                }
            }
        }
    }
}

extension SubjectType {
    func isDeleted(in subjectManager: SubjectManager) -> Bool {
        if let defaultSubject = self as? DefaultSubject {
            return subjectManager.isDeleted(defaultSubject)
        }
        return false
    }
}

struct ProblemSetsListView: View {
   let subject: SubjectType
   let problemSets: [ProblemSet]
   @EnvironmentObject var homeViewModel: HomeViewModel
   @State private var isShowingStudyView = false
   @State private var isShowingDeleteAlert = false
   @State private var problemSetToDelete: ProblemSet?
   @Binding var selectedTab: Int
   @State private var isEditMode = false
   @State private var showHelpAlert = false
   
   // Drag and drop state
   @State private var draggedProblemSet: ProblemSet?
   @State private var showingMergeAlert = false
   @State private var mergingProblemSets: (source: ProblemSet, target: ProblemSet)?
   @State private var mergeSetName = ""
   @State private var isTargeted = false
   
   private var shouldShowMergeTip: Bool {
       !UserDefaults.standard.bool(forKey: "hasSeenMergeTip") && problemSets.count >= 2
   }
   
   var body: some View {
       ScrollView {
           VStack(spacing: 12) {
               if shouldShowMergeTip {
                   VStack {
                       Text("💡 Tip: Drag one question set onto another to merge them!")
                           .font(.callout)
                           .padding()
                           .background(Color.blue.opacity(0.1))
                           .cornerRadius(8)
                   }
                   .padding(.horizontal)
                   .onAppear {
                       UserDefaults.standard.set(true, forKey: "hasSeenMergeTip")
                   }
               }
               
               LazyVStack(spacing: 12) {
                   ForEach(problemSets) { problemSet in
                       ReviewProblemSetCard(
                           subject: problemSet.resolvedSubject,
                           problemSet: problemSet,
                           isEditMode: isEditMode,
                           onDelete: {
                               problemSetToDelete = problemSet
                               isShowingDeleteAlert = true
                           },
                           onRename: { newName in
                               Task {
                                   await homeViewModel.renameProblemSet(problemSet, newName: newName)
                               }
                           }
                       )
                       .highPriorityGesture(
                           DragGesture(minimumDistance: 10)
                               .onChanged { _ in
                                   print("🔄 Drag detected")
                               }
                       )
                       .onTapGesture {
                           Task {
                               homeViewModel.setSelectedProblemSet(problemSet)
                               if let studyViewModel = homeViewModel.studyViewModel {
                                   await studyViewModel.resetState()
                                   studyViewModel.loadQuestions(problemSet.questions)
                                   await MainActor.run {
                                       withAnimation {
                                           selectedTab = 1
                                           isShowingStudyView = true
                                       }
                                   }
                               }
                           }
                       }
                       .draggable(problemSet) {
                           DragPreviewView(problemSet: problemSet)
                       }
                       .dropDestination(for: ProblemSet.self) { droppedItems, location in
                           print("📥 Drop detected on: \(problemSet.name)")
                           
                           guard let droppedSet = droppedItems.first else {
                               print("❌ No dropped set found")
                               return false
                           }
                           
                           if droppedSet.id != problemSet.id {
                               print("✨ Preparing to merge: \(droppedSet.name) into \(problemSet.name)")
                               mergingProblemSets = (droppedSet, problemSet)
                               mergeSetName = "\(droppedSet.name) + \(problemSet.name)"
                               showingMergeAlert = true
                               HapticManager.shared.impact(style: .medium)
                               return true
                           }
                           
                           print("⚠️ Cannot merge set with itself")
                           return false
                       } isTargeted: { isTargeted in
                           print("🎯 Target status for \(problemSet.name): \(isTargeted)")
                           withAnimation(.easeInOut(duration: 0.2)) {
                               self.isTargeted = isTargeted
                           }
                       }
                       .padding(.horizontal)
                       .background(
                           RoundedRectangle(cornerRadius: 12)
                               .fill(isTargeted ? Color.blue.opacity(0.1) : Color.clear)
                       )
                       .animation(.easeInOut(duration: 0.2), value: isTargeted)
                   }
               }
           }
           .padding(.vertical)
       }
       .navigationTitle("\(subject.displayName)")
       .toolbar {
           ToolbarItem(placement: .navigationBarTrailing) {
               HStack(spacing: 16) {
                   Button(action: {
                       showHelpAlert = true
                   }) {
                       Image(systemName: "questionmark.circle")
                           .imageScale(.large)
                           .foregroundColor(.blue)
                   }
                   
                   Button(action: {
                       withAnimation {
                           isEditMode.toggle()
                       }
                   }) {
                       Image(systemName: isEditMode ? "checkmark.circle.fill" : "pencil.circle")
                           .imageScale(.large)
                           .foregroundColor(isEditMode ? .green : .blue)
                   }
               }
           }
       }
       .alert("How to Merge Question Sets", isPresented: $showHelpAlert) {
           Button("Got it!", role: .cancel) {}
       } message: {
           Text("To merge question sets:\n\n1. Touch and hold a question set\n2. Drag it onto another question set\n3. Release to merge them\n\nThis is useful for combining related sets!")
       }
       .alert("Delete Problem Set", isPresented: $isShowingDeleteAlert) {
           Button("Cancel", role: .cancel) { }
           Button("Delete", role: .destructive) {
               if let problemSet = problemSetToDelete {
                   Task {
                       await homeViewModel.deleteProblemSet(problemSet)
                   }
               }
           }
       }
       .alert("Merge Problem Sets", isPresented: $showingMergeAlert) {
           TextField("New Set Name", text: $mergeSetName)
           Button("Cancel", role: .cancel) {
               mergingProblemSets = nil
               draggedProblemSet = nil
           }
           Button("Merge") {
               if let (source, target) = mergingProblemSets {
                   let mergedSet = ProblemSet.merge(
                       problemSets: [source, target],
                       name: mergeSetName
                   )
                   
                   Task {
                       print("💾 Saving merged set: \(mergedSet.name)")
                       await homeViewModel.saveProblemSet(mergedSet)
//                       await homeViewModel.deleteProblemSet(source)
//                       await homeViewModel.deleteProblemSet(target)
                       
                       mergingProblemSets = nil
                       draggedProblemSet = nil
                       HapticManager.shared.impact(style: .medium)
                   }
               }
           }
       } message: {
           if let sets = mergingProblemSets {
               Text("Merge '\(sets.source.name)' with '\(sets.target.name)'")
           }
       }
   }
}


private struct DragPreviewView: View {
   let problemSet: ProblemSet
   
   var body: some View {
       VStack(spacing: 4) {
           Text(problemSet.name)
               .font(.headline)
           Text("\(problemSet.questions.count) questions")
               .font(.caption)
       }
       .padding()
       .background(Color(.systemBackground))
       .cornerRadius(8)
       .shadow(radius: 3)
   }
}



// 별도의 row 컴포넌트로 분리
struct ProblemSetRow: View {
    let problemSet: ProblemSet
    @Binding var isShowingStudyView: Bool
    @Binding var isShowingDeleteAlert: Bool
    @Binding var problemSetToDelete: ProblemSet?
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var refreshTrigger = RefreshTrigger()
    @Binding var selectedTab: Int
    @State private var isTargeted = false
    @Binding var isEditMode: Bool  // 추가
    
    // 이름 변경을 위한 상태 변수
    @State private var displayName: String
    
    init(problemSet: ProblemSet,
         isShowingStudyView: Binding<Bool>,
         isShowingDeleteAlert: Binding<Bool>,
         problemSetToDelete: Binding<ProblemSet?>,
         selectedTab: Binding<Int>,
         isEditMode: Binding<Bool>) {  // 추가
        self.problemSet = problemSet
        self._isShowingStudyView = isShowingStudyView
        self._isShowingDeleteAlert = isShowingDeleteAlert
        self._problemSetToDelete = problemSetToDelete
        self._selectedTab = selectedTab
        self._isEditMode = isEditMode  // 추가
        self._displayName = State(initialValue: problemSet.name)
    }
    
    var body: some View {
        Button(action: {
            Task {
                homeViewModel.setSelectedProblemSet(problemSet)
                if let studyViewModel = homeViewModel.studyViewModel {
                    await studyViewModel.resetState()
                    studyViewModel.loadQuestions(problemSet.questions)
                    await MainActor.run {
                        withAnimation {
                            selectedTab = 1
                            isShowingStudyView = true
                        }
                    }
                }
            }
        }) {
            ReviewProblemSetCard(
                subject: problemSet.resolvedSubject,
                problemSet: problemSet.copy(withName: displayName),
                isEditMode: isEditMode,  // 추가
                onDelete: {
                    problemSetToDelete = problemSet
                    isShowingDeleteAlert = true
                },
                onRename: { newName in
                    Task {
                        await homeViewModel.renameProblemSet(problemSet, newName: newName)
                        await MainActor.run {
                            displayName = newName
                        }
                    }
                }
            )
        }
        .draggable(problemSet) {
            DragPreviewView(problemSet: problemSet)
        }
        .dropDestination(for: ProblemSet.self) { droppedItems, location in
            guard let droppedSet = droppedItems.first,
                  droppedSet.id != problemSet.id else {
                print("⚠️ Invalid drop operation")
                return false
            }
            
            print("🎯 Drop detected: \(droppedSet.name) onto \(problemSet.name)")
            
            let mergedSet = ProblemSet.merge(
                problemSets: [droppedSet, problemSet],
                name: "Merged: \(droppedSet.name) + \(problemSet.name)"
            )
            
            Task {
                await homeViewModel.saveProblemSet(mergedSet)
                HapticManager.shared.impact(style: .medium)
            }
            
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isTargeted = targeted
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: isTargeted ? 2 : 0)
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
        )
        .scaleEffect(isTargeted ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .onChange(of: problemSet.name) { newName in
            displayName = newName
        }
    }
}

extension ProblemSet {
    func copy(withName newName: String) -> ProblemSet {
        ProblemSet(
            id: self.id,
            subject: self.subject,
            subjectType: self.subjectType,
            subjectId: self.subjectId,
            subjectName: self.subjectName,
            questions: self.questions,
            createdAt: self.createdAt,
            educationLevel: self.educationLevel,
            name: newName  // 새 이름 사용
        )
    }
}


// StudyView destination을 별도 컴포넌트로 분리
// StudyDestinationView (기존과 동일)
struct StudyDestinationView: View {
    let problemSet: ProblemSet
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    var body: some View {
        Group {
            if let studyViewModel = homeViewModel.studyViewModel {
                StudyView(
                    questions: problemSet.questions,
                    studyViewModel: studyViewModel,
                    selectedTab: .constant(1)
                )
            } else {
                Text("Study ViewModel not available")
            }
        }
    }
}


class RefreshTrigger: ObservableObject {
    @Published var id = UUID()
    
    func refresh() {
        id = UUID()
    }
}


// 과목 행 컴포넌트
struct SubjectRow: View {
    // Style enum to handle different display modes
    enum Style {
        case navigation
        case management
    }
    
    let subject: SubjectType
    let style: Style
    let isDefault: Bool
    
    // Default initializer for navigation style
    init(subject: SubjectType) {
        self.subject = subject
        self.style = .navigation
        self.isDefault = false
    }
    
    // Management style initializer
    init(subject: SubjectType, isDefault: Bool) {
        self.subject = subject
        self.style = .management
        self.isDefault = isDefault
    }
    
    var body: some View {
        HStack {
            Image(systemName: subject.icon)
                .foregroundColor(subject.color)
                .font(style == .management ? .title2 : .body)
            
            Text(subject.displayName)
                .foregroundColor(.primary)
                .font(style == .management ? .body : .headline)
                .padding(.leading, style == .management ? 0 : 8)
            
            if style == .management {
                if isDefault {
                    Spacer()
                    Text("Default")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, style == .management ? 8 : 0)
    }
}
