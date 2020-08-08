import Vapor
import Fluent

struct SurveyController: APIController {

    typealias Model = SurveyDatabaseModel

    func find(req: Request) throws -> EventLoopFuture<SurveyDatabaseModel> {
        guard
            let surveyIdString = req.parameters.get("surveyId"),
            let surveyId = UUID(surveyIdString)
            else { throw Abort(.unprocessableEntity) }

        return SurveyDatabaseModel.find(surveyId, on: req.db)
            .unwrap(or: Abort(.notFound))
    }
}
