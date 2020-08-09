import Vapor
import VragenAPIModels

extension QuestionDatabaseModel: APIModel {

    typealias Input = QuestionCreateRequest
    typealias Output = QuestionResponse

    var output: Output {
        QuestionResponse(id: id?.uuidString ?? "unknown", title: title)
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
