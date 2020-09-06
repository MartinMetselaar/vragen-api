import Vapor
import VragenAPIModels

extension SurveyDatabaseModel: APIModel {

    typealias Input = SurveyCreateRequest
    typealias Output = SurveyResponse

    var output: Output? {
        guard let id = id else { return nil }
        return SurveyResponse(id: id, title: title)
    }

    var outputWithQuestions: SurveyWithQuestionsResponse? {
        guard let id = id else { return nil }
        return SurveyWithQuestionsResponse(id: id, title: title, questions: questions.outputsWithAnswers)
    }

    convenience init(input: Input) throws {
        self.init()
        self.title = input.title
    }

    func update(input: Input) throws {
        title = input.title
    }
}

extension SurveyResponse: Content {}
extension SurveyWithQuestionsResponse: Content {}
