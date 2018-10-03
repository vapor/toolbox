import SwiftSyntax

/// After a module has been compiled, this is
/// used to model the found behavior
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
    /// Most of the generation code doesn't need all the metadata associated
    /// with the complex types, so we convert the dictionary toa  simple
    /// (String,[String]) format
    fileprivate func simplified(withModuleName moduleName: String) -> SimplifiedTestSuite {
        var simple: SimplifiedTestSuite = []

        // simplify
        forEach { testCase, tests in
            let tests = tests.map { $0.identifier.description }
            let testCase = testCase.flattenedName()
            simple.append(.init(module: moduleName, name: testCase, tests: tests))
        }

        // alphabetical for consistency
        return simple.sorted { $0.name < $1.name }
    }
}
