import Vapor
import Fluent
import VragenAPIModels
import CodableCSV

struct SurveyController: APIController {

    typealias Model = SurveyDatabaseModel

    func getIncludingQuestionsAndAnswers(req: Request) throws -> EventLoopFuture<SurveyWithQuestionsResponse> {
        guard let surveyId = req.parameters.get("surveyId", as: UUID.self) else {
            throw Abort(.unprocessableEntity)
        }

        return SurveyDatabaseModel.query(on: req.db)
            .filter(\.$id == surveyId)
            .with(\.$questions)
            .with(\.$questions, { loader in
                loader.with(\.$answers)
            })
            .first()
            .unwrap(or: Abort(.notFound))
            .map { $0.outputWithQuestions }
            .unwrap(or: Abort(.internalServerError))
    }

    func results(req: Request) throws -> EventLoopFuture<Response> {
        guard let surveyId = req.parameters.get("surveyId", as: UUID.self) else {
            throw Abort(.unprocessableEntity)
        }

        let encoder = CSVEncoder() {
            $0.headers = ["userId", "question", "answer"]
        }

        return SubmittedAnswerDatabaseModel.query(on: req.db)
            .filter(\.$surveyId == surveyId)
            .with(\.$answer)
            .with(\.$question)
            .all()
            .mapEachCompact { $0.outputResult }
            .flatMapThrowing { try encoder.encode($0, into: String.self) }
            .map {
                let headers = HTTPHeaders([
                    (HTTPHeaders.Name.contentType.description, "text/csv"),
                ])
                return Response(status: .ok, headers: headers, body: .init(string: $0))
            }
    }

    func find(req: Request) throws -> EventLoopFuture<SurveyDatabaseModel> {
        guard let surveyId = req.parameters.get("surveyId", as: UUID.self) else {
            throw Abort(.unprocessableEntity)
        }

        return SurveyDatabaseModel.find(surveyId, on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func routes(routes: RoutesBuilder, id identifier: String) {
        let idPathComponent = PathComponent(stringLiteral: ":\(identifier)")

        // All
        routes.grouped(AdminAuthenticator())
            .grouped(AuthorizedUser.guardMiddleware())
            .get(use: self.all)

        // Create
        routes.grouped(AdminAuthenticator())
            .grouped(AuthorizedUser.guardMiddleware())
            .post(use: self.create)

        // Get
        routes.grouped(AdminAuthenticator())
            .grouped(AuthorizedUser.guardMiddleware())
            .get(idPathComponent, use: self.get)

        // Get including children
        routes.grouped(ConsumerAuthenticator()).grouped(AdminAuthenticator())
            .grouped(AuthorizedUser.guardMiddleware())
            .get(idPathComponent, "children", use: self.getIncludingQuestionsAndAnswers)

        // Download
        routes.grouped(AdminAuthenticator())
            .grouped(AuthorizedUser.guardMiddleware())
            .get(idPathComponent, "results", use: self.results)

        // Update
        routes
            .grouped(AdminAuthenticator())
            .grouped(AuthorizedUser.guardMiddleware())
            .post(idPathComponent, use: self.update)

        // Delete
        routes
            .grouped(AdminAuthenticator())
            .grouped(AuthorizedUser.guardMiddleware())
            .delete(idPathComponent, use: self.delete)
    }
}
