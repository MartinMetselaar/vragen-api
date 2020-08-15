import Vapor
import VragenAPIModels

extension AnswerDatabaseModel: APIModel {

    typealias Input = AnswerCreateRequest
    typealias Output = AnswerResponse

    var output: Output {
        AnswerResponse(id: id?.uuidString ?? "unknown", title: title)
    }

    convenience init(input: Input) throws {
        self.init()
        self.title = input.title
    }

    func update(input: Input) throws {
        title = input.title
    }
}

extension AnswerResponse: Content {}

extension Array where Element == AnswerDatabaseModel {
    var outputs: [Element.Output] { map { $0.output } }
}
