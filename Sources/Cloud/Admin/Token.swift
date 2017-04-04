import Foundation

public final class Token {
    public let refresh: String
    public fileprivate(set) var access: String {
        didSet {
            didUpdate?(self)
        }
    }

    // Currently just an estimation for debugging
    // TODO: Get from API?
    public var expiration: Date {
        let json = try? unwrap()
        let timestamp = json?["exp"]?.double
            ?? 0
        return Date(timeIntervalSince1970: timestamp)
    }

    public var didUpdate: ((Token) -> Void)?

    public init(access: String, refresh: String) {
        self.access = access
        self.refresh = refresh
    }
}

import HTTP
import Vapor

extension AdminApi {
    public final class AccessApi {
        public func refresh(_ token: Token) throws {
            let request = try Request(method: .get, uri: refreshEndpoint)
            request.refresh = token

            // No refresh middleware on token
            let response = try client.respond(to: request, through: [])
            guard let new = response.json?["accessToken"]?.string else {
                throw "Bad response to refresh request: \(response)"
            }
            token.access = new
        }
    }
}

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

        // attempting refresh
        try adminApi.access.refresh(token)
        // Reset access header
        request.access = token

        // Attempted refresh, trying again
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
