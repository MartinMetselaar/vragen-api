@testable import App
import Vapor
import XCTVapor

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
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/\(questionId)", headers: headers) { res in
            // Then
            let result = try res.content.decode(QuestionDatabaseModel.Output.self)
            XCTAssertEqual(result, question.output)
        }
    }

    func test_get_whenConsumerToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/\(questionId)", headers: headers) { res in
            // Then
            let result = try res.content.decode(QuestionDatabaseModel.Output.self)
            XCTAssertEqual(result, question.output)
        }
    }

    func test_get_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createUnknownToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/\(questionId)", headers: headers) { res in
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
