import Vapor
import VragenAPIModels

extension SubmittedAnswerDatabaseModel: APIModel {
    typealias Input = SubmitAnswerRequest
    typealias Output = SubmitAnswerResponse

    var output: Output? {
        SubmitAnswerResponse(userId: userId, surveyId: surveyId, questionId: questionId, answerId: answerId)
    }

    var outputResult: SurveyResultsResponse? {
        return SurveyResultsResponse(userId: userId, question: question.title, answer: answer.title)
    }

    convenience init(input: Input) throws {
        self.init()
        self.userId = input.userId
        self.surveyId = input.surveyId
        self.questionId = input.questionId
        self.answerId = input.answerId
    }

    func update(input: Input) throws {
        userId = input.userId
        surveyId = input.surveyId
        questionId = input.questionId
        answerId = input.answerId
    }
}

extension SubmitAnswerResponse: Content {}
extension SurveyResultsResponse: Content {}
