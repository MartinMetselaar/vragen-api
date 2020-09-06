import Vapor
import Fluent

struct QuestionController: APIController {

    typealias Model = QuestionDatabaseModel

    func all(req: Request) throws -> EventLoopFuture<Page<QuestionDatabaseModel.Output>> {
        guard let surveyId = req.parameters.get("surveyId", as: UUID.self) else {
            throw Abort(.unprocessableEntity)
        }
        
        return QuestionDatabaseModel.query(on: req.db)
            .filter(\.$surveyId == surveyId)
            .paginate(for: req)
            .map { page in
                .init(items: page.items.compactMap { $0.output }, metadata: page.metadata)
            }
    }

    func create(req: Request) throws -> EventLoopFuture<QuestionDatabaseModel.Output> {
        guard let surveyId = req.parameters.get("surveyId", as: UUID.self) else {
            throw Abort(.unprocessableEntity)
        }

        let input = try req.content.decode(QuestionDatabaseModel.Input.self)
        let model = try QuestionDatabaseModel(input: input)
        model.surveyId = surveyId
        return model.create(on: req.db)
            .map { model.output }
            .unwrap(or: Abort(.internalServerError))
    }

    func find(req: Request) throws -> EventLoopFuture<QuestionDatabaseModel> {
        guard let surveyId = req.parameters.get("surveyId", as: UUID.self) else {
            throw Abort(.unprocessableEntity)
        }

        guard let questionId = req.parameters.get("questionId", as: UUID.self) else {
            throw Abort(.unprocessableEntity)
        }

        return QuestionDatabaseModel.query(on: req.db)
            .filter(\.$id == questionId)
            .filter(\.$surveyId == surveyId)
            .first()
            .unwrap(or: Abort(.notFound))
    }
}
