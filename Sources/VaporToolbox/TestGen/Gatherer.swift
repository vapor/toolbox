import SwiftSyntax

class Gatherer: SyntaxVisitor {
    private var potentialTestCases: [ClassDeclSyntax] = []
    private var potentialTestFunctions: [FunctionDeclSyntax] = []

    override func visit(_ node: ClassDeclSyntax) {
        defer { super.visit(node) }
        potentialTestCases.append(node)
    }

    override func visit(_ node: FunctionDeclSyntax) {
        defer { super.visit(node) }
        guard node.looksLikeTestFunction else { return }
        potentialTestFunctions.append(node)
    }
}

extension Gatherer {
    private func testCases() throws -> [ClassDeclSyntax] {
        return try potentialTestCases.filter { cd in
            try cd.inheritsXCTestCase(using: potentialTestCases)
        }
    }

    private func tests() throws -> [FunctionDeclSyntax] {
        let validCases = try testCases()
        return try potentialTestFunctions.filter { f in
            return try f.testCase(from: validCases) != nil
        }
    }

    func makeTestSuite() throws -> [ClassDeclSyntax: [FunctionDeclSyntax]] {
        var testSuite: [ClassDeclSyntax: [FunctionDeclSyntax]] = [:]
        let validTests = try tests()
        let validCases = try testCases()
        for test in validTests {
            guard
                let testCase = try test.testCase(from: validCases)
                else { throw "unable to find test case for: \(test.identifier)" }
            var existing = testSuite[testCase] ?? []
            existing.append(test)
            testSuite[testCase] = existing
        }
        return testSuite
    }
}
