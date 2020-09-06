import Vapor
import Fluent
import FluentPostgresDriver

// Called before your application initializes.
public func configure(_ app: Application) throws {
    try app.databases.use(.postgres(url: Environment.databaseURL), as: .psql)

    try routes(app)

    app.migrations.add([
        CreateDatabaseMigration(),
        AddSubmittedAnswerMigration(),
    ])
}
