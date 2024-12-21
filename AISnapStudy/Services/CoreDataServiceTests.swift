import XCTest // XCTAssertTrue를 사용하기 위해 필요

class CoreDataServiceTests: XCTestCase {
    let coreDataService = CoreDataService.shared
    
    func testUpdateQuestionBookmark() throws {
        // Given
        let question = CDQuestion(context: coreDataService.viewContext)
        question.id = UUID().uuidString // String 타입
        question.isSaved = false
        
        try coreDataService.viewContext.save()
        
        // When
        // Optional 언래핑
        guard let questionId = question.id else {
            XCTFail("Question ID should not be nil")
            return
        }
        try coreDataService.updateQuestionBookmark(questionId, isSaved: true)
        
        // Then
        XCTAssertTrue(question.isSaved)
    }
}
