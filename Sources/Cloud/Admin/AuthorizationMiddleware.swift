import HTTP
import Vapor
import URI
import Sockets

public enum AuthorizationError: Error {
    case tokenExpired
}

class AuthorizationMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response = try next.respond(to: request)
        guard response.isExpiredToken else { return response }
        throw AuthorizationError.tokenExpired
    }
}

extension Response {
    fileprivate var isExpiredToken: Bool {
        guard let json = json else { return false }

        let isError = json["error"]?.bool ?? false
        guard isError else { return false }

        return json["identifier"]?
            .string?
            .hasSuffix("authenticationTimeout")
            ?? false
    }
}
