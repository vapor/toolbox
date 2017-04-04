// Console extensions to be merged back in

extension LoadingBar {
    public func perform<T>(_ op: () throws -> T) rethrows -> T {
        defer { fail() }
        start()
        let result = try op()
        finish()
        return result
    }
}
