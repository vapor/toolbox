import Foundation

public final class Token {
    public fileprivate(set) var access: String
    public let refresh: String
    // TODO: Get from API?
    public fileprivate(set) var expiration: Date

    public init(access: String, refresh: String, expiration: Date? = nil) {
        self.access = access
        self.refresh = refresh

        // 15 minute timeout, 1 minute to be sure
        let fourteenMinutes = 60.0 * 14.0
        self.expiration = expiration ?? Date(timeIntervalSinceNow: fourteenMinutes)
    }

    fileprivate func updateExpiration() {
        // 15 minute timeout, 1 minute to be sure
        let fourteenMinutes = 60.0 * 14.0
        self.expiration = Date(timeIntervalSinceNow: fourteenMinutes)
    }
}

import HTTP
import Vapor
//
//let autoRefresh = [TokenRefreshMiddleware()]
//
//class TokenRefreshMiddleware: Middleware {
//    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
//        let response = try next.respond(to: request)
//        // If we've already tried a refresh, then there's nothing for us to do
//        guard !request.isRefreshRequest else { return response }
//        // ensure that response is forbidden auth and might require refresh
//        guard response.requiresRefresh else { return response }
//        // ensure there is a token associated with the request
//        guard let token = request.token else { return response }
//
//        print("Attempting refresh")
//        let refreshed = try adminApi.access.refresh(token)
//        token.access = refreshed.access
//        token.updateExpiration()
//        request.access = token
//
//        // Attempted refresh, trying again
//        print("Refresh successful, trying again")
//        return try next.respond(to: request)
//    }
//}

enum CloudClientError: Error {
    case requiresLogin
}
import Sockets

public final class CloudClient<Wrapped: ClientProtocol>: ClientProtocol {
    public let wrapped: Wrapped

    public required init(hostname: String, port: Sockets.Port, _ securityLayer: SecurityLayer) throws {
        wrapped = try Wrapped(hostname: hostname, port: port, securityLayer)
    }

    public func respond(to request: Request) throws -> Response {
        let response = try wrapped.respond(to: request)
        // If we've already tried a refresh, then there's nothing for us to do
        guard !request.isRefreshRequest else { return response }
        // ensure that response is forbidden auth and might require refresh
        guard response.requiresRefresh else { return response }
        // ensure there is a token associated with the request
        guard let token = request.token else { return response }

        print("Attempting refresh")
        let refreshed = try adminApi.access.refresh(token)
        token.access = refreshed.access
        token.updateExpiration()
        request.access = token

        // Attempted refresh, trying again
        print("Refresh successful, trying again")
        return try wrapped.respond(to: request)
    }
}

extension Token: Equatable {}
public func == (lhs: Token, rhs: Token) -> Bool {
    return lhs.access == rhs.access
        && lhs.refresh == rhs.refresh
}

extension Response {
    // Attempt refresh for 401, 403, 419
    var requiresRefresh: Bool {
        return [401, 403, 419].contains(status.statusCode)
    }
}
