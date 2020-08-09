import Vapor
import Fluent

struct AnswerController: APIController {

    typealias Model = AnswerDatabaseModel

    func all(req: Request) throws -> EventLoopFuture<Page<AnswerDatabaseModel.Output>> {
        guard let surveyIdString = req.parameters.get("surveyId"),
            let surveyId = UUID(uuidString: surveyIdString) else {
                throw Abort(.unprocessableEntity)
        }

        guard let questionIdString = req.parameters.get("questionId"),
            let questionId = UUID(uuidString: questionIdString) else {
                throw Abort(.unprocessableEntity)
        }

        return AnswerDatabaseModel.query(on: req.db)
            .filter(\.$questionId == questionId)
            .join(QuestionDatabaseModel.self, on: \AnswerDatabaseModel.$questionId == \QuestionDatabaseModel.$id)
            .filter(QuestionDatabaseModel.self, \.$surveyId == surveyId)
            .paginate(for: req)
            .map {
                $0.map { $0.output }
            }
    }

    func find(req: Request) throws -> EventLoopFuture<AnswerDatabaseModel> {
        guard let surveyIdString = req.parameters.get("surveyId"),
            let surveyId = UUID(uuidString: surveyIdString) else {
                throw Abort(.unprocessableEntity)
        }

        guard let questionIdString = req.parameters.get("questionId"),
            let questionId = UUID(uuidString: questionIdString) else {
                throw Abort(.unprocessableEntity)
        }

        guard let answerIdString = req.parameters.get("answerId"),
            let answerId = UUID(uuidString: answerIdString) else {
                throw Abort(.unprocessableEntity)
        }

        return AnswerDatabaseModel.query(on: req.db)
            .filter(\.$id == answerId)
            .filter(\.$questionId == questionId)
            .join(QuestionDatabaseModel.self, on: \AnswerDatabaseModel.$questionId == \QuestionDatabaseModel.$id)
            .filter(QuestionDatabaseModel.self, \.$surveyId == surveyId)
            .first()
            .unwrap(or: Abort(.notFound))
    }
}
