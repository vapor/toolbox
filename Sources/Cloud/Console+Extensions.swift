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

extension ConsoleProtocol {
    public func verify(information: [String: String]) throws {
        for (key, value) in information {
            self.print("\(key): ", newLine: false)
            self.info(value)
        }
        guard confirm("Is the above information correct?") else {
            throw "Cancelled"
        }
    }
}
