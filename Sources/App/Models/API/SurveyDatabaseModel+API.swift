import Vapor
import VragenAPIModels

extension SurveyDatabaseModel: APIModel {

    typealias Input = SurveyCreateRequest
    typealias Output = SurveyResponse

    var output: Output {
        SurveyResponse(id: id?.uuidString ?? "unknown", title: title)
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
