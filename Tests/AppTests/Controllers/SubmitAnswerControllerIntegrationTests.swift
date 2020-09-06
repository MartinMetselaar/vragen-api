@testable import App
import Vapor
import XCTVapor
import Fluent
import VragenAPIModels

final class SubmitAnswerControllerIntegrationTests: XCTestCase {

    private var app: Application!

    // MARK: - Setup

    override func setUpWithError() throws {
        app = try createTestApp()
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    // MARK: - Submit

    func test_submit_whenConsumerToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)
        let answer = createAnswerModel(title: "answer", questionId: question.id)

        let input = SubmitAnswerRequest(userId: "123", surveyId: survey.id!, questionId: question.id!, answerId: answer.id!)

        // When
        try app.test(.POST, "api/v1/submit/", headers: headers, content: input) { res in
            // Then
            let result = try res.content.decode(SubmittedAnswerDatabaseModel.Output.self)
            XCTAssertEqual(result.userId, "123")
            XCTAssertEqual(result.answerId, answer.id)
            XCTAssertEqual(result.questionId, question.id)
            XCTAssertEqual(result.surveyId, survey.id)
        }
    }

    func test_submit_whenAdminToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()

        // When
        try app.test(.POST, "api/v1/submit/", headers: headers) { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        }

        // Then
        let _ = SubmittedAnswerDatabaseModel.query(on: app.db)
            .count()
            .map { count in
                XCTAssertEqual(count, 0)
            }
    }

    func test_submit_whenInvokedTwiceButWithADifferentAnswer_shouldUpdatePreviousAnswer() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let userId = "123"
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)
        let answer1 = createAnswerModel(title: "answer 1", questionId: question.id)
        let answer2 = createAnswerModel(title: "answer 2", questionId: question.id)

        let input = SubmitAnswerRequest(userId: userId, surveyId: survey.id!, questionId: question.id!, answerId: answer1.id!)

        // When
        try app.test(.POST, "api/v1/submit/", headers: headers, content: input) { res in
            // Then
            let result = try res.content.decode(SubmittedAnswerDatabaseModel.Output.self)
            XCTAssertEqual(result.userId, userId)
            XCTAssertEqual(result.answerId, answer1.id)
            XCTAssertEqual(result.questionId, question.id)
            XCTAssertEqual(result.surveyId, survey.id)
        }

        // Given
        let changedInput = SubmitAnswerRequest(userId: userId, surveyId: survey.id!, questionId: question.id!, answerId: answer2.id!)

        // When
        try app.test(.POST, "api/v1/submit/", headers: headers, content: changedInput) { res in
            // Then
            let result = try res.content.decode(SubmittedAnswerDatabaseModel.Output.self)
            XCTAssertEqual(result.userId, userId)
            XCTAssertEqual(result.answerId, answer2.id)
            XCTAssertEqual(result.questionId, question.id)
            XCTAssertEqual(result.surveyId, survey.id)
        }

        // Then
        let _ = SubmittedAnswerDatabaseModel.query(on: app.db)
            .count()
            .map { count in
                XCTAssertEqual(count, 1)
            }
    }

    func test_submit_whenSubmittingAnswerThatDoesNotBelongToQuestion_shouldReturnNotFound() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let question1 = createQuestionModel(title: "question 1", surveyId: survey.id)
        let question2 = createQuestionModel(title: "question 2", surveyId: survey.id)
        let answer2 = createAnswerModel(title: "answer 2", questionId: question2.id)

        let input = SubmitAnswerRequest(userId: "123", surveyId: survey.id!, questionId: question1.id!, answerId: answer2.id!)

        // When
        try app.test(.POST, "api/v1/submit/", headers: headers, content: input) { res in
            // Then
            XCTAssertEqual(res.status, .notFound)
        }

        // Then
        let _ = SubmittedAnswerDatabaseModel.query(on: app.db)
            .count()
            .map { count in
                XCTAssertEqual(count, 0)
            }
    }

    func test_submit_whenSubmittingAnswersToTwoDifferentQuestions_shouldStoreBothAnswers() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let userId = "123"
        let survey = createSurveyModel(title: "survey")
        let question1 = createQuestionModel(title: "question 1", surveyId: survey.id)
        let answer1 = createAnswerModel(title: "answer 1", questionId: question1.id)

        let question2 = createQuestionModel(title: "question 2", surveyId: survey.id)
        let answer2 = createAnswerModel(title: "answer 2", questionId: question2.id)

        let firstInput = SubmitAnswerRequest(userId: userId, surveyId: survey.id!, questionId: question1.id!, answerId: answer1.id!)

        // When
        try app.test(.POST, "api/v1/submit/", headers: headers, content: firstInput) { res in
            // Then
            let result = try res.content.decode(SubmittedAnswerDatabaseModel.Output.self)
            XCTAssertEqual(result.userId, userId)
            XCTAssertEqual(result.answerId, answer1.id)
            XCTAssertEqual(result.questionId, question1.id)
            XCTAssertEqual(result.surveyId, survey.id)
        }

        // Given
        let secondInput = SubmitAnswerRequest(userId: userId, surveyId: survey.id!, questionId: question2.id!, answerId: answer2.id!)

        // When
        try app.test(.POST, "api/v1/submit/", headers: headers, content: secondInput) { res in
            // Then
            let result = try res.content.decode(SubmittedAnswerDatabaseModel.Output.self)
            XCTAssertEqual(result.userId, userId)
            XCTAssertEqual(result.answerId, answer2.id)
            XCTAssertEqual(result.questionId, question2.id)
            XCTAssertEqual(result.surveyId, survey.id)
        }

        // Then
        let _ = SubmittedAnswerDatabaseModel.query(on: app.db)
            .count()
            .map { count in
                XCTAssertEqual(count, 2)
            }
    }

    func test_submit_whenInvokedByTwoDifferentUsers_should() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let survey = createSurveyModel(title: "survey")
        let question = createQuestionModel(title: "question", surveyId: survey.id)
        let answer = createAnswerModel(title: "answer", questionId: question.id)

        let firstUser = "123"
        let firstInput = SubmitAnswerRequest(userId: firstUser, surveyId: survey.id!, questionId: question.id!, answerId: answer.id!)

        // When
        try app.test(.POST, "api/v1/submit/", headers: headers, content: firstInput) { res in
            // Then
            let result = try res.content.decode(SubmittedAnswerDatabaseModel.Output.self)
            XCTAssertEqual(result.userId, firstUser)
            XCTAssertEqual(result.answerId, answer.id)
            XCTAssertEqual(result.questionId, question.id)
            XCTAssertEqual(result.surveyId, survey.id)
        }

        // Given
        let secondUser = "789"
        let secondInput = SubmitAnswerRequest(userId: secondUser, surveyId: survey.id!, questionId: question.id!, answerId: answer.id!)

        // When
        try app.test(.POST, "api/v1/submit/", headers: headers, content: secondInput) { res in
            // Then
            let result = try res.content.decode(SubmittedAnswerDatabaseModel.Output.self)
            XCTAssertEqual(result.userId, secondUser)
            XCTAssertEqual(result.answerId, answer.id)
            XCTAssertEqual(result.questionId, question.id)
            XCTAssertEqual(result.surveyId, survey.id)
        }

        // Then
        let _ = SubmittedAnswerDatabaseModel.query(on: app.db)
            .count()
            .map { count in
                XCTAssertEqual(count, 2)
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
        guard let questionId = questionId else { fatalError("AnswerId should actually not be optional") }

        let model = AnswerDatabaseModel(title: title, questionId: questionId)
        try? model.save(on: app.db).wait()

        return model
    }
}
