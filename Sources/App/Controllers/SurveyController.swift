import Vapor
import Fluent

struct SurveyController: APIController {

    typealias Model = SurveyDatabaseModel

    func find(req: Request) throws -> EventLoopFuture<SurveyDatabaseModel> {
        guard let surveyId = req.parameters.get("surveyId", as: UUID.self) else {
            throw Abort(.unprocessableEntity)
        }

        return SurveyDatabaseModel.find(surveyId, on: req.db)
            .unwrap(or: Abort(.notFound))
    }
}
