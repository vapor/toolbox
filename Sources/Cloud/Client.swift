import Vapor
import Sockets
import Foundation
import HTTP

// TODO: Add middleware to find 500 response errors and throw proper swift errors

public enum CloudClientError: Error {
    /// Refresh token is expired,
    /// fresh login required
    case loginRequired
    case badGateway(Response, for: Request)
    case badResponse(Response, for: Request)
}

/// This client should be used for accessing Vapor Cloud apis
/// it will automatically attempt token refreshing when possible
/// on unauthorized endpoints
public final class CloudClient<Wrapped: ClientProtocol>: ClientProtocol {
    public let wrapped: Wrapped

    public required init(hostname: String, port: Sockets.Port, _ securityLayer: SecurityLayer) throws {
        wrapped = try Wrapped(hostname: hostname, port: port, securityLayer)
    }

    public func respond(to request: Request) throws -> Response {
        let response = try wrapped.respond(to: request)
        try assertValid(request, response)
        let processed = try handle(request, response)
        try errorPass(request: request, response: processed)
        return processed
    }

    private func handle(_ request: Request, _ response: Response) throws -> Response {
        // If we've already tried a refresh, then forward it back
        guard !request.isRefreshRequest else { return response }
        // ensure that response is forbidden auth and might require refresh
        guard response.requiresRefresh else { return response }
        // ensure there is a token associated with the request
        guard let token = request.token else { return response }
        // try a refresh request
        return try refresh(request, with: token)
    }

    private func refresh(_ request: Request, with token: Token) throws -> Response {
        // attempting refresh
        try adminApi.access.refresh(token)
        // Reset access header
        request.access = token

        // Attempted refresh, trying again
        return try wrapped.respond(to: request)
    }

    private func assertValid(_ request: Request, _ response: Response) throws {
        // If we are getting Auth forbiddens on refresh request,
        // user is required to login again
        if request.isRefreshRequest && response.requiresRefresh {
            throw CloudClientError.loginRequired
        }
    }

    private func errorPass(request: Request, response: Response) throws {
        if response.status.statusCode == 502 { throw CloudClientError.badGateway(response, for: request) }
        guard let json = response.json else { return }
        guard let _ = json["error"] else { return }
        throw CloudClientError.badResponse(response, for: request)
    }

}

extension Response {
    // Attempt refresh for 401, 403, 419
    var requiresRefresh: Bool {
        return [401, 403, 419].contains(status.statusCode)
    }
}
