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
    public func detail(_ key: String, _ value: String) {
        self.print("\(key): ", newLine: false)
        self.info(value)
    }
    
    public func verify(information: [String: String]) throws {
        for (key, value) in information {
            self.detail(key, value)
        }
        guard confirm("Is the above information correct?") else {
            throw "Cancelled"
        }
    }
    
    public func clear(lines: Int) {
        for _ in 0..<lines {
            self.clear(.line)
        }
    }
    public func verifyAboveCorrect() throws {
        guard confirm("Is the above information correct?") else {
            throw "Cancelled"
        }
    }
}
