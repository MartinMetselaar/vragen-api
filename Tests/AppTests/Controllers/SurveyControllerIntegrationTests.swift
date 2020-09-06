@testable import App
import Vapor
import Fluent
import XCTVapor
import VragenAPIModels

final class SurveyControllerIntegrationTests: XCTestCase {

    private var app: Application!

    // MARK: - Setup

    override func setUpWithError() throws {
        app = try createTestApp()
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    // MARK: - Get

    func test_get_whenAdminToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let model = createSurveyModel(title: "title")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(identifier)", headers: headers) { res in
            // Then
            let result = try res.content.decode(SurveyDatabaseModel.Output.self)
            XCTAssertEqual(result, model.output)
        }
    }

    func test_get_whenConsumerToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let model = createSurveyModel(title: "title")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(identifier)", headers: headers) { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    // MARK: - Get including questions and answers

    func test_get_whenSurveyHasQuestions_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let model = createSurveyModel(title: "title")
        let _ = createQuestionModel(title: "question 1", surveyId: model.id)
        let _ = createQuestionModel(title: "question 2", surveyId: model.id)

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(identifier)/children", headers: headers) { res in
            // Then
            let result = try res.content.decode(SurveyWithQuestionsResponse.self)
            XCTAssertNotNil(result)
            XCTAssertEqual(result.id, model.id)
            XCTAssertEqual(result.title, model.title)

            XCTAssertEqual(result.questions.count, 2)
        }
    }

    // MARK: - All

    func test_all_whenCorrectToken_shouldReturnModels() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let survey = createSurveyModel(title: "survey")

        // When
        try app.test(.GET, "api/v1/surveys/", headers: headers) { res in
            // Then
            let result = try res.content.decode(VragenAPIModels.Page<SurveyDatabaseModel.Output>.self)
            XCTAssertNotNil(result.items.first)
            XCTAssertEqual(result.items.first?.id, survey.id)
            XCTAssertEqual(result.items.first?.title, survey.title)
        }
    }

    func test_all_whenConsumerToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let _ = createSurveyModel(title: "survey")

        // When
        try app.test(.GET, "api/v1/surveys/", headers: headers) { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    // MARK: - Create

    func test_create_whenCorrectToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let input = SurveyDatabaseModel.Input(title: "input")

        // When
        try app.test(.POST, "/api/v1/surveys/", headers: headers, content: input) { res in
            // Then
            let result = try res.content.decode(SurveyDatabaseModel.Output.self)
            XCTAssertEqual(result.title, "input")
        }
    }

    func test_create_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let input = SurveyDatabaseModel.Input(title: "input")

        // When
        try app.test(.POST, "/api/v1/surveys/", headers: headers, content: input) { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    // MARK: - Helpers

    func createSurveyModel(title: String) -> SurveyDatabaseModel {
        let model = SurveyDatabaseModel(title: title)
        try? model.save(on: app.db).wait()

        return model
    }

    func createQuestionModel(title: String, surveyId: UUID?) -> QuestionDatabaseModel {
        guard let surveyId = surveyId else { fatalError("SurveyId should actually not be optional") }

        let model = QuestionDatabaseModel(title: title, surveyId: surveyId)
        try? model.save(on: app.db).wait()

        return model
    }
}
