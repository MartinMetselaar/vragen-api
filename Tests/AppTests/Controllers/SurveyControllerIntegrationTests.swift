@testable import App
import Vapor
import Fluent
import XCTVapor
import VragenAPIModels
import CodableCSV

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
        try app.test(.GET, "api/v1/surveys/\(identifier)", headers: headers, afterResponse: { res in
            // Then
            let result = try res.content.decode(SurveyDatabaseModel.Output.self)
            XCTAssertEqual(result, model.output)
        })
    }

    func test_get_whenConsumerToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let model = createSurveyModel(title: "title")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(identifier)", headers: headers, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
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
        try app.test(.GET, "api/v1/surveys/\(identifier)/children", headers: headers, afterResponse: { res in
            // Then
            let result = try res.content.decode(SurveyWithQuestionsResponse.self)
            XCTAssertNotNil(result)
            XCTAssertEqual(result.id, model.id)
            XCTAssertEqual(result.title, model.title)

            XCTAssertEqual(result.questions.count, 2)
        })
    }

    // MARK: - All

    func test_all_whenCorrectToken_shouldReturnModels() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let survey = createSurveyModel(title: "survey")

        // When
        try app.test(.GET, "api/v1/surveys/", headers: headers, afterResponse: { res in
            // Then
            let result = try res.content.decode(VragenAPIModels.Page<SurveyDatabaseModel.Output>.self)
            XCTAssertNotNil(result.items.first)
            XCTAssertEqual(result.items.first?.id, survey.id)
            XCTAssertEqual(result.items.first?.title, survey.title)
        })
    }

    func test_all_whenConsumerToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let _ = createSurveyModel(title: "survey")

        // When
        try app.test(.GET, "api/v1/surveys/", headers: headers, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Create

    func test_create_whenCorrectToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let input = SurveyDatabaseModel.Input(title: "input")

        // When
        try app.test(.POST, "/api/v1/surveys/", headers: headers, content: input, afterResponse: { res in
            // Then
            let result = try res.content.decode(SurveyDatabaseModel.Output.self)
            XCTAssertEqual(result.title, "input")
        })
    }

    func test_create_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let input = SurveyDatabaseModel.Input(title: "input")

        // When
        try app.test(.POST, "/api/v1/surveys/", headers: headers, content: input, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Results

    func test_results_whenCorrectToken_shouldReturnHTTPStatusOk() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let survey = createSurveyModel(title: "survey")

        let surveyId = survey.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/results", headers: headers, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, HTTPStatus.ok)
        })
    }

    func test_results_whenCorrectToken_shouldReturnContentTypeCSV() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let survey = createSurveyModel(title: "survey")

        let surveyId = survey.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/results", headers: headers, afterResponse: { res in
            // Then
            let body = String(buffer: res.body)
            XCTAssertEqual(body, "userId,question,answer\n")
            XCTAssertEqual(res.headers.contentType?.description, "text/csv")
        })
    }

    func test_results_whenCorrectTokenAndSubmittedAnswer_shouldReturnCSVString() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let userId = "user-id-123"
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)
        let answer = createAnswerModel(title: "answer", questionId: question.id)
        let _ = createSubmittedAnswerModel(userId: userId, surveyId: survey.id, questionId: question.id, answerId: answer.id)

        let surveyId = survey.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/results", headers: headers, afterResponse: { res in
            // Then
            let body = String(buffer: res.body)
            XCTAssertEqual(body, "userId,question,answer\nuser-id-123,question,answer\n")
            XCTAssertEqual(res.headers.contentType?.description, "text/csv")
        })
    }

    func test_results_whenCorrectTokenAndSubmittedAnswers_shouldReturnDecodableCSVResponse() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let survey = createSurveyModel(title: "survey")
        let question1 = createQuestionModel(title: "question 1", surveyId: survey.id)
        let answer11 = createAnswerModel(title: "answer 11", questionId: question1.id)
        let answer12 = createAnswerModel(title: "answer 12", questionId: question1.id)

        let question2 = createQuestionModel(title: "question 2", surveyId: survey.id)
        let answer21 = createAnswerModel(title: "answer 21", questionId: question2.id)
        let answer22 = createAnswerModel(title: "answer 22", questionId: question2.id)

        let _ = createSubmittedAnswerModel(userId: "1", surveyId: survey.id, questionId: question1.id, answerId: answer11.id)
        let _ = createSubmittedAnswerModel(userId: "1", surveyId: survey.id, questionId: question2.id, answerId: answer21.id)
        let _ = createSubmittedAnswerModel(userId: "2", surveyId: survey.id, questionId: question1.id, answerId: answer11.id)
        let _ = createSubmittedAnswerModel(userId: "3", surveyId: survey.id, questionId: question1.id, answerId: answer12.id)
        let _ = createSubmittedAnswerModel(userId: "4", surveyId: survey.id, questionId: question2.id, answerId: answer21.id)
        let _ = createSubmittedAnswerModel(userId: "5", surveyId: survey.id, questionId: question2.id, answerId: answer22.id)

        let surveyId = survey.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/results", headers: headers, afterResponse: { res in
            // Then
            let body = String(buffer: res.body)

            var configuration = CSVDecoder.Configuration()
            configuration.headerStrategy = .firstLine
            let decoder = CSVDecoder(configuration: configuration)
            let result = try decoder.decode([SurveyResultsResponse].self, from: body)

            XCTAssertEqual(result.count, 6)
        })
    }

    func test_results_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")

        let surveyId = survey.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(surveyId)/results", headers: headers, afterResponse: { res in
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

    func createAnswerModel(title: String, questionId: UUID?) -> AnswerDatabaseModel {
        guard let questionId = questionId else { fatalError("QuestionId should actually not be optional") }

        let model = AnswerDatabaseModel(title: title, questionId: questionId)
        try? model.save(on: app.db).wait()

        return model
    }

    func createSubmittedAnswerModel(userId: String, surveyId: UUID?, questionId: UUID?, answerId: UUID?) -> SubmittedAnswerDatabaseModel {
        guard let answerId = answerId else { fatalError("AnswerId should actually not be optional") }
        guard let questionId = questionId else { fatalError("QuestionId should actually not be optional") }
        guard let surveyId = surveyId else { fatalError("SurveyId should actually not be optional") }

        let model = SubmittedAnswerDatabaseModel(userId: userId, answerId: answerId, questionId: questionId, surveyId: surveyId)
        try? model.save(on: app.db).wait()

        return model
    }
}
