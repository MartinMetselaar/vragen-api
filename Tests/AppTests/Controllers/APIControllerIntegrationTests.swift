@testable import App
import XCTVapor
import FluentSQLiteDriver

final class APIControllerIntegrationTests: XCTestCase {

    private var app: Application!

    // MARK: - Setup

    override func setUpWithError() throws {
        app = Application(.testing)
        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.databases.default(to: .sqlite)

        app.migrations.add(CreateTestDatabaseMigration())

        let controller = ModelController()
        controller.routes(routes: app.routes, id: "modelId")

        try app.autoMigrate().wait()
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    // MARK: - All

    func test_all_whenCorrectToken_shouldReturnModels() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let model = createDatabaseModel(title: "title")

        // When
        try app.test(.GET, "/", headers: headers, afterResponse: { res in
            // Then
            let result = try res.content.decode(Page<DatabaseModel.Output>.self)
            XCTAssertEqual(result.items, [model.output])
        })
    }

    func test_all_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()

        // When
        try app.test(.GET, "/", headers: headers, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Get

    func test_get_whenAdminToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let model = createDatabaseModel(title: "title")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.GET, "/\(identifier)", headers: headers, afterResponse: { res in
            // Then
            let result = try res.content.decode(DatabaseModel.Output.self)
            XCTAssertEqual(result, model.output)
        })
    }

    func test_get_whenConsumerToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let model = createDatabaseModel(title: "title")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.GET, "/\(identifier)", headers: headers, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Create

    func test_create_whenCorrectToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let input = DatabaseModel.Input(title: "input")

        // When
        try app.test(.POST, "/", headers: headers, content: input, afterResponse: { res in
            // Then
            let result = try res.content.decode(DatabaseModel.Output.self)
            XCTAssertEqual(result.title, "input")
        })
    }

    func test_create_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let input = DatabaseModel.Input(title: "input")

        // When
        try app.test(.POST, "/", headers: headers, content: input, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Update

    func test_update_whenAdminToken_shouldUpdateModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let model = createDatabaseModel(title: "Original title")

        let identifier = model.id?.uuidString ?? ""

        let input = DatabaseModel.Input(title: "Update title")

        // When
        try app.test(.POST, "/\(identifier)", headers: headers, content: input, afterResponse: { res in
            // Then
            let result = try res.content.decode(DatabaseModel.Output.self)
            XCTAssertNotEqual(result, model.output)
            XCTAssertEqual(result.title, "Update title")
        })
    }

    func test_update_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let model = createDatabaseModel(title: "Original title")

        let identifier = model.id?.uuidString ?? ""

        let input = DatabaseModel.Input(title: "Update title")

        // When
        try app.test(.POST, "/\(identifier)", headers: headers, content: input, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Delete

    func test_delete_whenAdminToken_shouldDeleteModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let model = createDatabaseModel(title: "Soon to be deleted")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.DELETE, "/\(identifier)", headers: headers, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .ok)
            DatabaseModel.query(on: app.db).count().whenSuccess { count in
                XCTAssertEqual(count, 0)
            }
        })
    }

    func test_delete_whenUnauthorizedToken_shouldNotDeleteModel() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let model = createDatabaseModel(title: "Can't touch this")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.DELETE, "/\(identifier)", headers: headers, afterResponse: { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
            DatabaseModel.query(on: app.db).count().whenSuccess { count in
                XCTAssertEqual(count, 1)
            }
        })
    }

    // MARK: - Helpers

    func createDatabaseModel(title: String) -> DatabaseModel {
        let model = DatabaseModel(title: title)
        try? model.save(on: app.db).wait()

        return model
    }

    // MARK: -

    final class DatabaseModel: Model, APIModel {
        static let schema = "table"

        struct FieldKeys {
            static var title: FieldKey { "title" }
        }

        @ID() var id: UUID?
        @Field(key: FieldKeys.title) var title: String

        init() {}

        init(id: UUID? = nil,
             title: String
        ) {
            self.id = id
            self.title = title
        }

        struct InputContent: Content {
            let title: String
        }

        struct OutputContent: Content, Equatable {
            let id: UUID
            let title: String
        }

        typealias Input = InputContent
        typealias Output = OutputContent

        var output: OutputContent? {
            guard let id = id else { return nil }
            return OutputContent(id: id, title: title)
        }

        convenience init(input: InputContent) throws {
            self.init()
            self.title = input.title
        }

        func update(input: InputContent) throws {
            title = input.title
        }
    }

    // MARK: -

    struct CreateTestDatabaseMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.eventLoop.flatten([
                database.schema(DatabaseModel.schema)
                    .id()
                    .field(DatabaseModel.FieldKeys.title, .string, .required)
                    .create(),
            ])
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.eventLoop.flatten([
                database.schema(DatabaseModel.schema).delete(),
            ])
        }
    }

    // MARK: -

    struct ModelController: APIController {
        typealias Model = DatabaseModel

        func find(req: Request) throws -> EventLoopFuture<DatabaseModel> {
            guard let id = req.parameters.get("modelId", as: UUID.self) else {
                throw Abort(.unprocessableEntity)
            }

            return DatabaseModel.find(id, on: req.db)
                .unwrap(or: Abort(.notFound))
        }
    }
}
