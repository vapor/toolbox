import JSON
import Vapor
import HTTP

let middleware = [AuthorizationMiddleware()]

extension AdminApi {
    public final class UserApi {
        public func get(with token: Token) throws -> User {
            let request = try Request(method: .get, uri: meEndpoint)
            request.access = token

            let response = try client.respond(to: request, through: middleware)
            return try User(node: response.json)
        }
    }
}
