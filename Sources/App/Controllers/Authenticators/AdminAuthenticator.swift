import Vapor

struct AdminAuthenticator: BearerAuthenticator {
    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if bearer.token == Environment.adminToken {
            request.auth.login(AuthorizedUser())
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}
