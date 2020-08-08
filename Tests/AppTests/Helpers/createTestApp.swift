@testable import App
import Vapor

func createTestApp() throws -> Application {
    let app = Application(.testing)
    try configure(app)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.databases.default(to: .sqlite)
    try app.autoMigrate().wait()
    return app
}
