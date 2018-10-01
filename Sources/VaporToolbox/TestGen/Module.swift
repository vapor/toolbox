import SwiftSyntax

final class Module {
    let name: String
    let suite: TestSuite
    let simplified: SimplifiedTestSuite

    init(name: String, suite: TestSuite) {
        self.name = name
        self.suite = suite
        self.simplified = suite.simplified(withModuleName: name)
    }
}

extension Dictionary where Key == ClassDeclSyntax, Value == [FunctionDeclSyntax] {
    func simplified(withModuleName moduleName: String) -> SimplifiedTestSuite {
        var simple: SimplifiedTestSuite = []

        // simplify
        forEach { testCase, tests in
            let tests = tests.map { $0.identifier.description }
            let testCase = testCase.flattenedName()

            // Can't have `extension Module.Module {` where testCase
            // and Module name are the same or compiler crashes
            let validTestCaseName: String
            if testCase == moduleName {
                validTestCaseName = testCase
            } else {
                validTestCaseName = moduleName + "." + testCase
            }

            simple.append(.init(name: validTestCaseName, tests: tests))
        }

        // alphabetical for consistency
        return simple.sorted { $0.name < $1.name }
    }
}
