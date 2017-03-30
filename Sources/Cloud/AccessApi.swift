import HTTP
import Vapor

extension AdminApi {
    public final class AccessApi {
        public func refresh(with token: Token) throws -> Token {
            let request = try Request(method: .get, uri: refreshEndpoint)
            request.refresh = token
            let response = try client.respond(to: request)
            guard let refresh = response.json?["accessToken"]?.string else {
                throw "Bad response to refresh request: \(response)"
            }
            return Token(access: token.access, refresh: refresh)
        }
    }
}
