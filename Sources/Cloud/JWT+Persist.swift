import JWT

extension JWT {
    /// Creates a JWT from the globally persisted Token
    static func persisted(with console: ConsoleProtocol) throws -> JWT {
        let token = try Token.global(with: console)
        return try JWT(token: token.access)
    }
}


extension CloudAPIFactory {
    /// Creates a CloudAPI client authenticated
    /// with the global JWT token
    func makeAuthedClient(with console: ConsoleProtocol) throws -> CloudAPI {
        let jwt = try JWT.persisted(with: console)
        return try makeClient(using: jwt)
    }
}
