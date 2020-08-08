import Vapor

struct ConsumerAuthenticator: BearerAuthenticator {
    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if bearer.token == Environment.consumerToken {
            request.auth.login(AuthorizedUser())
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}
