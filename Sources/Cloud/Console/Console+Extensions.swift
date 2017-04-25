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

extension ConsoleProtocol {
    public func giveChoice<T>(title: String, in array: [T]) throws -> T {
        return try giveChoice(title: title, in: array, display: { "\($0)" })
    }
    
    public func giveChoice<T>(title: String, in array: [T], display: (T) -> String) throws -> T {
        info(title)
        array.enumerated().forEach { idx, item in
            let offset = idx + 1
            info("\(offset): ", newLine: false)
            let description = display(item)
            print(description)
        }
        
        var res: T?
        while res == nil {
            output("> ", style: .plain, newLine: false)
            let raw = input()
            guard let idx = Int(raw), (1...array.count).contains(idx) else {
                // .count is implicitly offset, no need to adjust
                clear(.line)
                continue
            }
            
            // undo previous offset back to 0 indexing
            let offset = idx - 1
            res = array[offset]
        }
        
        // + 1 for > input line
        // + 1 for title line
        let lines = array.count + 2
        for _ in 1...lines {
            clear(.line)
        }
        
        return res!
    }
}
