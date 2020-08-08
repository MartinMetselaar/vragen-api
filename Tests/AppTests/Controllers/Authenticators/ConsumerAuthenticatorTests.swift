@testable import App
import Vapor
import XCTVapor

final class ConsumerAuthenticatorTests: XCTestCase {

    private var app: Application!

    private var sut: ConsumerAuthenticator!

    // MARK: - Setup

    override func setUpWithError() throws {
        app = try createTestApp()

        sut = ConsumerAuthenticator()
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    // MARK: - Authenticate

    func test_authenticate_whenAdminToken_shouldNotAuthenticateUser() throws {
        // Given
        let request = Request(application: app, method: .GET, on: app.eventLoopGroup.next())
        let bearer = BearerAuthorization(token: Constants.Token.admin)

        // When
        _ = sut.authenticate(bearer: bearer, for: request)

        // Then
        XCTAssertFalse(request.auth.has(AuthorizedUser.self))
    }

    func test_authenticate_whenConsumerToken_shouldAuthenticateUser() throws {
        // Given
        let request = Request(application: app, method: .GET, on: app.eventLoopGroup.next())
        let bearer = BearerAuthorization(token: Constants.Token.consumer)

        // When
        _ = sut.authenticate(bearer: bearer, for: request)

        // Then
        XCTAssertTrue(request.auth.has(AuthorizedUser.self))
    }

    func test_authenticate_whenOtherToken_shouldNotAuthenticateUser() throws {
        // Given
        let request = Request(application: app, method: .GET, on: app.eventLoopGroup.next())
        let bearer = BearerAuthorization(token: Constants.Token.unknown)

        // When
        _ = sut.authenticate(bearer: bearer, for: request)

        // Then
        XCTAssertFalse(request.auth.has(AuthorizedUser.self))
    }
}
