import Vapor
import VragenAPIModels

extension QuestionDatabaseModel: APIModel {

    typealias Input = QuestionCreateRequest
    typealias Output = QuestionResponse

    var output: Output? {
        guard let id = id else { return nil }
        return QuestionResponse(id: id, title: title)
    }

    var outputWithAnswers: QuestionWithAnswersResponse? {
        guard let id = id else { return nil }
        return QuestionWithAnswersResponse(id: id, title: title, answers: answers.outputs)
    }

    convenience init(input: Input) throws {
        self.init()
        self.title = input.title
    }

    func update(input: Input) throws {
        title = input.title
    }
}

extension QuestionResponse: Content {}
extension QuestionWithAnswersResponse: Content {}

extension Array where Element == QuestionDatabaseModel {
    var outputsWithAnswers: [QuestionWithAnswersResponse] { compactMap { $0.outputWithAnswers } }
}
