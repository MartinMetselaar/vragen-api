import Vapor

extension Environment {

    static var adminToken: String {
        guard let token = Environment.get("ADMIN_TOKEN") else {
            fatalError("ADMIN_TOKEN not configured")
        }
        return token
    }

    static var consumerToken: String {
        guard let token = Environment.get("CONSUMER_TOKEN") else {
            fatalError("CONSUMER_TOKEN not configured")
        }
        return token
    }
}
