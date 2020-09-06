import Vapor
import Fluent

struct SubmitAnswerController {

    func submit(req: Request) throws -> EventLoopFuture<SubmittedAnswerDatabaseModel.Output> {
        let input = try req.content.decode(SubmittedAnswerDatabaseModel.Input.self)
        let model = try SubmittedAnswerDatabaseModel(input: input)

        let answerId = input.answerId
        let questionId = input.questionId
        let surveyId = input.surveyId

        // First search if it does not answer a question from a different survey
        return AnswerDatabaseModel.query(on: req.db)
            .filter(\.$id == answerId)
            .filter(\.$questionId == questionId)
            .join(QuestionDatabaseModel.self, on: \AnswerDatabaseModel.$questionId == \QuestionDatabaseModel.$id)
            .filter(QuestionDatabaseModel.self, \.$surveyId == surveyId)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowingFuture { _ -> EventLoopFuture<SubmittedAnswerDatabaseModel.Output> in
                // Find if the question was already answered
                return try self.find(req: req)
                    .flatMap { (result) -> EventLoopFuture<()> in
                        // When it is not answered yet
                        guard let result = result else {
                            return model.create(on: req.db)
                        }

                        // Update the answer when it already existed
                        result.answerId = answerId
                        return result.update(on: req.db)
                }.map { model.output }
                .unwrap(or: Abort(.internalServerError))
            }
    }

    func find(req: Request) throws -> EventLoopFuture<SubmittedAnswerDatabaseModel?> {
        let input = try req.content.decode(SubmittedAnswerDatabaseModel.Input.self)

        return SubmittedAnswerDatabaseModel.query(on: req.db)
            .filter(\.$userId == input.userId)
            .filter(\.$questionId == input.questionId)
            .filter(\.$surveyId == input.surveyId)
            .first()
    }

    func routes(routes: RoutesBuilder) {
        // Submit
        routes.grouped(ConsumerAuthenticator())
            .grouped(AuthorizedUser.guardMiddleware())
            .post(use: self.submit)
    }
}
