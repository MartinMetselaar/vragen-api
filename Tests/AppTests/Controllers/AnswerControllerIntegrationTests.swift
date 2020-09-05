@testable import App
import Vapor
import XCTVapor
import Fluent
import VragenAPIModels

final class AnswerControllerIntegrationTests: XCTestCase {

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
        let answer = createAnswerModel(title: "answer", questionId: question.id)

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""
        let answerId = answer.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/\(questionId)/answers/\(answerId)", headers: headers) { res in
            // Then
            let result = try res.content.decode(AnswerDatabaseModel.Output.self)
            XCTAssertEqual(result, answer.output)
        }
    }

    func test_get_whenConsumerToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)
        let answer = createAnswerModel(title: "answer", questionId: question.id)

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""
        let answerId = answer.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/\(questionId)/answers/\(answerId)", headers: headers) { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    // MARK: - All

    func test_all_whenCorrectToken_shouldReturnModels() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)
        let answer = createAnswerModel(title: "question", questionId: question.id)

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/\(questionId)/answers/", headers: headers) { res in
            // Then
            let result = try res.content.decode(VragenAPIModels.Page<AnswerDatabaseModel.Output>.self)
            XCTAssertEqual(result.items, [answer.output])
        }
    }

    func test_all_whenConsumerToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/questions/\(questionId)/answers/", headers: headers) { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    // MARK: - Create

    func test_create_whenCorrectToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)
        let input = AnswerCreateRequest(title: "answer")

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""

        // When
        try app.test(.POST, "api/v1/surveys/\(surveyId)/questions/\(questionId)/answers/", headers: headers, content: input) { res in
            // Then
            let result = try res.content.decode(AnswerDatabaseModel.Output.self)
            XCTAssertEqual(result.title, "answer")
        }
    }

    func test_create_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)
        let input = AnswerCreateRequest(title: "answer")

        let surveyId = survey.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""

        // When
        try app.test(.POST, "api/v1/surveys/\(surveyId)/questions/\(questionId)/answers/", headers: headers, content: input) { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    func test_create_whenQuestionIsFromDifferentSurvey_shouldReturnNotFound() throws {
        let headers = HTTPHeaders.createAdminToken()
        let survey1 = createSurveyModel(title: "survey 1")
        let survey2 = createSurveyModel(title: "survey 2")
        let question = createQuestionModel(title: "question", surveyId: survey1.id)
        let input = AnswerCreateRequest(title: "answer")

        let surveyId = survey2.id?.uuidString ?? ""
        let questionId = question.id?.uuidString ?? ""

        // When
        try app.test(.POST, "api/v1/surveys/\(surveyId)/questions/\(questionId)/answers/", headers: headers, content: input) { res in
            // Then
            XCTAssertEqual(res.status, .notFound)
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

    func createAnswerModel(title: String, questionId: UUID?) -> AnswerDatabaseModel {
        guard let questionId = questionId else { fatalError("QuestionId should actually not be optional") }

        let model = AnswerDatabaseModel(title: title, questionId: questionId)
        try? model.save(on: app.db).wait()

        return model
    }
}
