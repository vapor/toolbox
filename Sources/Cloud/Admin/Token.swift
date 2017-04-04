import Bits
import JSON
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

extension Token: Equatable {}
public func == (lhs: Token, rhs: Token) -> Bool {
    return lhs.access == rhs.access
        && lhs.refresh == rhs.refresh
}

extension Token {
    internal func unwrap() throws -> JSON {
        let comps = access.components(separatedBy: ".")
        guard comps.count == 3 else { throw "Invalid access token." }

        let data = comps[1].makeBytes().base64URLDecoded
        return try JSON(bytes: data)
    }
}

extension JSON {
    func prettyString() throws -> String {
        let serialized = try serialize(prettyPrint: true)
        return serialized.makeString()
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
