@testable import App
import Vapor
import XCTVapor

final class SurveyControllerIntegrationTests: XCTestCase {

    private var app: Application!

    // MARK: - Setup

    override func setUpWithError() throws {
        app = try createTestApp()
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    // MARK: - Get

    func test_get_whenAdminToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createAdminToken()
        let model = createSurveyModel(title: "title")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(identifier)", headers: headers) { res in
            // Then
            let result = try res.content.decode(SurveyDatabaseModel.Output.self)
            XCTAssertEqual(result, model.output)
        }
    }

    func test_get_whenConsumerToken_shouldReturnModel() throws {
        // Given
        let headers = HTTPHeaders.createConsumerToken()
        let model = createSurveyModel(title: "title")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(identifier)", headers: headers) { res in
            // Then
            let result = try res.content.decode(SurveyDatabaseModel.Output.self)
            XCTAssertEqual(result, model.output)
        }
    }

    func test_get_whenUnauthorizedToken_shouldReturnUnauthorized() throws {
        // Given
        let headers = HTTPHeaders.createUnknownToken()
        let model = createSurveyModel(title: "title")

        let identifier = model.id?.uuidString ?? ""

        // When
        try app.test(.GET, "api/v1/surveys/\(identifier)", headers: headers) { res in
            // Then
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    // MARK: - Helpers

    func createSurveyModel(title: String) -> SurveyDatabaseModel {
        let model = SurveyDatabaseModel(title: title)
        try? model.save(on: app.db).wait()

        return model
    }
}
