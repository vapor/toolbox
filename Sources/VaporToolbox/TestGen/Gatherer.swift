import Foundation
import SwiftSyntax

typealias TestSuite = [ClassDeclSyntax: [FunctionDeclSyntax]]

struct SimpleTestCase {
    let name: String
    let tests: [String]
}

typealias SimplifiedTestSuite = [SimpleTestCase]

class Gatherer: SyntaxVisitor {
    fileprivate private(set) var potentialTestCases: [ClassDeclSyntax] = []
    fileprivate private(set) var potentialTestFunctions: [FunctionDeclSyntax] = []
    fileprivate var _testSuite: TestSuite? = nil
    
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
    static func processFile(at url: String) throws -> Gatherer {
        let url = URL(fileURLWithPath: url)
        let sourceFile = try SyntaxTreeParser.parse(url)
        let gatherer = Gatherer()
        gatherer.visit(sourceFile)
        return gatherer
    }
}

extension Gatherer {
    fileprivate convenience init(potentialTestFunctions: [FunctionDeclSyntax], potentialTestCases: [ClassDeclSyntax]) {
        self.init()
        self.potentialTestFunctions = potentialTestFunctions
        self.potentialTestCases = potentialTestCases
    }
}

extension Array where Element == Gatherer {
    func merge() -> Gatherer {
        let potentialTestFunctions = self.reduce([]) { val, next in val + next.potentialTestFunctions }
        let potentialTestCases = self.reduce([]) { val, next in val + next.potentialTestCases }
        return Gatherer(potentialTestFunctions: potentialTestFunctions, potentialTestCases: potentialTestCases)
    }
}

extension Gatherer {
    private func testCases() -> [ClassDeclSyntax] {
        return potentialTestCases.filter { cd in
            cd.inheritsXCTestCase(using: potentialTestCases)
        }
    }

    private func tests() -> [FunctionDeclSyntax] {
        let validCases = testCases()
        return potentialTestFunctions.filter { f in
            return f.testCase(from: validCases) != nil
        }
    }

    func makeTestSuite() throws -> TestSuite {
        if let suite = _testSuite { return suite }

        // make if necessary
        var testSuite: TestSuite = [:]
        let validTests = tests()
        let validCases = testCases()
        for test in validTests {
            guard
                let testCase = test.testCase(from: validCases)
                else { throw "unable to find test case for: \(test.identifier)" }
            var existing = testSuite[testCase] ?? []
            existing.append(test)
            testSuite[testCase] = existing
        }

        // set to holder to keep prevent duplicate processing
        _testSuite = testSuite
        return testSuite
    }
}
