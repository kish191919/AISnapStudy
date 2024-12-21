// AISnapStudyTests/CoreDataServiceTests.swift
import XCTest
@testable import AISnapStudy  // 메인 타겟 import 추가

class CoreDataServiceTests: XCTestCase {
    let coreDataService = CoreDataService.shared
    
    override func setUp() {
        super.setUp()
        // 테스트 준비 코드
    }
    
    override func tearDown() {
        // 테스트 정리 코드
        super.tearDown()
    }
    
    func testUpdateQuestionBookmark() throws {
        // Given
        let question = CDQuestion(context: coreDataService.viewContext)
        question.id = UUID().uuidString
        question.isSaved = false
        
        try coreDataService.viewContext.save()
        
        // When
        guard let questionId = question.id else {
            XCTFail("Question ID should not be nil")
            return
        }
        try coreDataService.updateQuestionBookmark(questionId, isSaved: true)
        
        // Then
        XCTAssertTrue(question.isSaved)
    }
}
