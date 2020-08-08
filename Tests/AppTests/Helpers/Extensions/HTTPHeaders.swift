import Vapor

extension HTTPHeaders {
    init(bearerToken: String) {
        self.init([("Authorization", "Bearer \(bearerToken)")])
    }

    static func createAdminToken() -> HTTPHeaders {
        return HTTPHeaders(bearerToken: Constants.Token.admin)
    }

    static func createConsumerToken() -> HTTPHeaders {
        return HTTPHeaders(bearerToken: Constants.Token.consumer)
    }

    static func createUnknownToken() -> HTTPHeaders {
        return HTTPHeaders(bearerToken: Constants.Token.unknown)
    }
}
