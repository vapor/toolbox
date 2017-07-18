extension CloudAPIFactory {
    /// Creates a CloudAPI client authenticated
    /// with the global JWT token
    func makeAuthedClient(with console: ConsoleProtocol) throws -> CloudAPI {
        let factory = try makeAccessTokenFactory(with: console)
        return try makeClient(using: factory)
    }
    
    /// Creates a CloudAPI client authenticated
    /// with the global JWT token
    func makeAccessTokenFactory(with console: ConsoleProtocol) throws -> AccessTokenFactory {
        let cache = try TokenCache.global(with: console)
        let factory = try AccessTokenFactory(cache, self)
        return factory
    }
}
