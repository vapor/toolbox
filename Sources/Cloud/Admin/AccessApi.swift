import HTTP
import Vapor

extension AdminApi {
    public final class AccessApi {
        public func refresh(_ token: Token) throws -> Token {
            let request = try Request(method: .get, uri: refreshEndpoint)
            request.refresh = token

            // No refresh middleware on token
            let response = try client.respond(to: request, through: [])
            guard let new = response.json?["accessToken"]?.string else {
                throw "Bad response to refresh request: \(response)"
            }
            return Token(access: new, refresh: token.refresh)
        }
    }
}
