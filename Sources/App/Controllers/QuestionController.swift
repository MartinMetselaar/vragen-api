import Vapor
import Fluent

struct QuestionController: APIController {

    typealias Model = QuestionDatabaseModel

    func all(req: Request) throws -> EventLoopFuture<Page<QuestionDatabaseModel.Output>> {
        guard let surveyIdString = req.parameters.get("surveyId"),
            let surveyId = UUID(uuidString: surveyIdString) else {
                throw Abort(.unprocessableEntity)
        }
        return QuestionDatabaseModel.query(on: req.db)
            .filter(\.$surveyId == surveyId)
            .paginate(for: req)
            .map {
                $0.map { $0.output }
            }
    }

    func find(req: Request) throws -> EventLoopFuture<QuestionDatabaseModel> {
        guard let surveyIdString = req.parameters.get("surveyId"),
            let surveyId = UUID(uuidString: surveyIdString) else {
                throw Abort(.unprocessableEntity)
        }

        guard let questionIdString = req.parameters.get("questionId"),
            let questionId = UUID(uuidString: questionIdString) else {
                throw Abort(.unprocessableEntity)
        }

        return QuestionDatabaseModel.query(on: req.db)
            .filter(\.$id == questionId)
            .filter(\.$surveyId == surveyId)
            .first()
            .unwrap(or: Abort(.notFound))
    }
}
