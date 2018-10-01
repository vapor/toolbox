import SwiftSyntax

final class Module {
    let name: String
    // TODO: Protect Privately?
    let suite: TestSuite
    fileprivate var _simplifiedSuite: [(testCase: String, tests: [String])]? = nil

    init(name: String, suite: TestSuite) {
        self.name = name
        self.suite = suite
    }

    func simplifiedSuite() throws -> [(testCase: String, tests: [String])] {
        if let val = _simplifiedSuite { return val }

        var simple: [(testCase: String, tests: [String])] = []

        // simplify
        try suite.forEach { testCase, tests in
            let tests = tests.map { $0.identifier.description }
            let testCase = try testCase.flattenedName()

            // Can't have `extension Module.Module {` where testCase
            // and Module name are the same or compiler crashes
            let validTestCaseName: String
            if testCase == name {
                validTestCaseName = testCase
            } else {
                validTestCaseName = name + "." + testCase
            }
            simple.append((validTestCaseName, tests))
        }

        // alphabetical for consistency
        let val = simple.sorted { $0.testCase < $1.testCase }
        _simplifiedSuite = val
        return val
    }
}
