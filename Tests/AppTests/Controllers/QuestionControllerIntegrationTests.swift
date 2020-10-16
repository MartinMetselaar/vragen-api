@testable import App
import Vapor
import Fluent
import XCTVapor
import VragenAPIModels

final class QuestionControllerIntegrationTests: XCTestCase {

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
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/\(questionId)", headers: headers, afterResponse: { res in
            // Then
            let result = try res.content.decode(QuestionDatabaseModel.Output.self)
            XCTAssertEqual(result, question.output)
        })
    }

    func test_get_whenConsumerToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/\(questionId)", headers: headers, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - All

    func test_all_whenCorrectToken_shouldReturnModels() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)

        let surveyId = survey.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/", headers: headers, afterResponse: { res in
            // Then
            let result = try res.content.decode(VragenAPIModels.Page<QuestionDatabaseModel.Output>.self)
            XCTAssertEqual(result.items, [question.output])
        })
    }

    func test_all_whenConsumerToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let _ = createQuestionModel(title: "question", surveyId: survey.id)

        let surveyId = survey.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/", headers: headers, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Create

    func test_create_whenCorrectToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let survey = createSurveyModel(title: "survey")
        let input = QuestionCreateRequest(title: "question")

        let surveyId = survey.id?.uuidString ?? ""

        // When
        try app.test(.POST, "api/v1/surveys/\(surveyId)/questions/", headers: headers, content: input, afterResponse: { res in
            // Then
            let result = try res.content.decode(QuestionDatabaseModel.Output.self)
            XCTAssertEqual(result.title, "question")
        })
    }

    func test_create_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let input = QuestionCreateRequest(title: "question")

        let surveyId = survey.id?.uuidString ?? ""

        // When
        try app.test(.POST, "api/v1/surveys/\(surveyId)/questions/", headers: headers, content: input, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
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
