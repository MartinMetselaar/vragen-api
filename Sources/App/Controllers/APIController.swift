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
        guard req.auth.has(AuthorizedUser.self) else {
            throw Abort(.unauthorized)
        }

        return Model.query(on: req.db)
            .paginate(for: req)
            .map { test in
                test.map { $0.output }
            }
    }

    func get(req: Request) throws -> EventLoopFuture<Model.Output> {
        guard req.auth.has(AuthorizedUser.self) else {
            throw Abort(.unauthorized)
        }

        return try find(req: req)
        .map { $0.output }
    }

    func create(req: Request) throws -> EventLoopFuture<Model.Output> {
        guard req.auth.has(AuthorizedUser.self) else {
            throw Abort(.unauthorized)
        }

        let input = try req.content.decode(Model.Input.self)
        let model = try Model(input: input)
        return model.save(on: req.db)
            .map { model.output }
    }

    func update(req: Request) throws -> EventLoopFuture<Model.Output> {
        guard req.auth.has(AuthorizedUser.self) else {
            throw Abort(.unauthorized)
        }

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
        guard req.auth.has(AuthorizedUser.self) else {
            throw Abort(.unauthorized)
        }
        
        return try find(req: req)
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
    }

    func routes(routes: RoutesBuilder, id identifier: String) {
        let idPathComponent = PathComponent(stringLiteral: ":\(identifier)")

        // All
        routes.grouped(AdminAuthenticator())
            .get(use: self.all)

        // Create
        routes.grouped(AdminAuthenticator())
            .post(use: self.create)

        // Get
        routes.grouped(ConsumerAuthenticator()).grouped(AdminAuthenticator())
            .get(idPathComponent, use: self.get)

        // Update
        routes
            .grouped(AdminAuthenticator())
            .post(idPathComponent, use: self.update)

        // Delete
        routes
            .grouped(AdminAuthenticator())
            .delete(idPathComponent, use: self.delete)
    }
}
