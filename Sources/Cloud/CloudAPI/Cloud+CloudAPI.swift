extension CloudAPIFactory {
    /// Creates a CloudAPI client authenticated
    /// with the global JWT token
    func makeAuthedClient(with console: ConsoleProtocol) throws -> CloudAPI {
        let cache = try TokenCache.global(with: console)
        let factory = try AccessTokenFactory(cache, self)
        return try makeClient(using: factory)
    }
}
