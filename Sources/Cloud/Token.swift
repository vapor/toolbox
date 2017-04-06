import Bits
import JSON
import Foundation

/// All endpoints beyond initial login/signup
/// require a secure access token to be passed.
/// This is a model of said token.
public final class Token {
    /// Refresh value does NOT get updated.
    /// It is valid for 7 days, and is used to 
    /// refresh the access token which
    /// expires every 15 minutes.
    public let refresh: String

    /// The access token used for authorized
    /// access into the Vapor Cloud system
    public fileprivate(set) var access: String {
        didSet {
            didUpdate?(self)
        }
    }

    /// This is when the 'access' token will expire.
    /// There is currently no metadata about refresh 
    /// expiration, on failed refresh,
    /// user should login again.
    public var expiration: Date {
        let json = try? unwrap()
        let timestamp = json?["exp"]?.double
            ?? 0
        return Date(timeIntervalSince1970: timestamp)
    }

    /// On a refresh, the 'access' value will be 
    /// updated and trigger this to notify 
    /// a listener
    public var didUpdate: ((Token) -> Void)?

    /// Create a new token with an access key
    /// and a refresh key that can be used
    /// for future updates
    public init(access: String, refresh: String) {
        self.access = access
        self.refresh = refresh
    }
}

extension Token {
    /// The access token is a JWT token 
    /// and it includes some light metadata
    /// that is useful in things like debugging.
    /// Use this to access underlying token values.
    internal func unwrap() throws -> JSON {
        let comps = access.components(separatedBy: ".")
        guard comps.count == 3 else { throw "Invalid access token." }

        let data = comps[1].makeBytes().base64URLDecoded
        return try JSON(bytes: data)
    }
}

extension JSON {
    /// Return a pretty print, user friendly,
    /// formatted JSON string
    func prettyString() throws -> String {
        let serialized = try serialize(prettyPrint: true)
        return serialized.makeString()
    }
}

extension Token: Equatable {}
public func == (lhs: Token, rhs: Token) -> Bool {
    return lhs.access == rhs.access
        && lhs.refresh == rhs.refresh
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

let tokenStorageKey = "cloud-client:token"
let refreshStorageKey = "cloud-client:isRefreshRequest"

extension Request {
    internal var access: Token {
        get { fatalError() }
        set {
            headers["Authorization"] = "Bearer \(newValue.access)"
            storage[tokenStorageKey] = newValue
            storage[refreshStorageKey] = false
        }
    }
    internal var refresh: Token {
        get { fatalError() }
        set {
            headers["Authorization"] = "Bearer \(newValue.refresh)"
            storage[tokenStorageKey] = newValue
            storage[refreshStorageKey] = true
        }
    }

    internal var token: Token? {
        return storage[tokenStorageKey] as? Token
    }

    internal var isRefreshRequest: Bool {
        return storage[refreshStorageKey] as? Bool ?? false

    }
}
