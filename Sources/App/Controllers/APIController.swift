import Vapor
import Fluent

protocol APIController {
    associatedtype Model: APIModel

    func find(req: Request) throws -> EventLoopFuture<Model>

    func all(req: Request) throws -> EventLoopFuture<Page<Model.Output>>
    func get(req: Request) throws -> EventLoopFuture<Model.Output>
    func create(req: Request) throws -> EventLoopFuture<Model.Output>
    func update(req: Request) throws -> EventLoopFuture<Model.Output>
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus>

    func routes(routes: RoutesBuilder, id identifier: String)
}

extension APIController {
    func all(req: Request) throws -> EventLoopFuture<Page<Model.Output>> {
        return Model.query(on: req.db)
            .paginate(for: req)
            .map { $0.map { $0.output } }
    }

    func get(req: Request) throws -> EventLoopFuture<Model.Output> {
        return try find(req: req)
        .map { $0.output }
    }

    func create(req: Request) throws -> EventLoopFuture<Model.Output> {
        let input = try req.content.decode(Model.Input.self)
        let model = try Model(input: input)
        return model.create(on: req.db)
            .map { model.output }
    }

    func update(req: Request) throws -> EventLoopFuture<Model.Output> {
        let input = try req.content.decode(Model.Input.self)

        return try find(req: req)
            .flatMapThrowing { model -> Model in
                try model.update(input: input)
                return model
            }
            .flatMap { model in
                return model.update(on: req.db).map { model.output }
            }
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return try find(req: req)
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
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
