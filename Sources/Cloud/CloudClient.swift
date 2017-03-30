import HTTP
import Vapor
import URI
import Sockets

/*
 {
 "debugReason": "Access token has expired",
 "error": true,
 "identifier": "Vapor.Abort.authenticationTimeout",
 "reason": "Access token has expired"
 }
 */

// TODO:
// this should go into toolbox
// and be passed into admin api
// then this can handle all the login logic
// this should initialize with a console for login input and info to fetch
// token

enum AuthorizationError: Error {
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

public final class Cloud<Wrapped: ClientProtocol>: ClientProtocol {
    let instance: Wrapped
    public init(hostname: String, port: Port, _ securityLayer: SecurityLayer) throws {
        instance = try Wrapped(hostname: hostname, port: port, securityLayer)
    }
    public func respond(to request: Request) throws -> Response {
        print("Intercept unauthorized requests and reauthorize")
        let response = try instance.respond(to: request)

        return response
    }
}
