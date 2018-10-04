import Foundation
import SwiftSyntax

typealias TestSuite = [ClassDeclSyntax: [FunctionDeclSyntax]]

struct SimpleTestCase {
    let module: String
    let name: String
    let tests: [String]

    var extensionName: String {
        // Can't have `extension Module.Module {` where testCase
        // and Module name are the same or compiler crashes
        let validExtensionName: String
        if name == module {
            validExtensionName = name
        } else {
            validExtensionName = module + "." + name
        }
        return validExtensionName
    }

    // overridden classes require property overrides
    // it gets complicated unnecessarily, so we generate
    // unique test function names for each
    var testsVariableName: String {
        let stripped = name.components(separatedBy: ".").joined()
        return "__all\(stripped)Tests"
    }
}

typealias SimplifiedTestSuite = [SimpleTestCase]

/// To properly generate the file, we can't simply process
/// a single file, but rather need to process the
/// module (and ideally dependencies) in its entirety to
/// understand the file
class Gatherer: SyntaxVisitor {
    fileprivate private(set) var potentialTestCases: [ClassDeclSyntax] = []
    fileprivate private(set) var potentialTestFunctions: [FunctionDeclSyntax] = []
    fileprivate var _testSuite: TestSuite? = nil
    
    override func visit(_ node: ClassDeclSyntax) {
        print("Visiting: \(node.flattenedName())")
        defer { super.visit(node) }
        potentialTestCases.append(node)
    }

    override func visit(_ node: FunctionDeclSyntax) {
        print("Visiting: \(node.identifier)")
        defer { super.visit(node) }
        guard node.looksLikeTestFunction else { return }
        potentialTestFunctions.append(node)
    }
}

extension Gatherer {
    static func processFile(at url: String) throws -> Gatherer {
        print("Processing file: \(url)")
        let url = URL(fileURLWithPath: url)
        let sourceFile = try SyntaxTreeParser.parse(url)
        print("Got source")
        let gatherer = Gatherer()
        print("Made gatherer")
        gatherer.visit(sourceFile)
        print("Gathered sourceFile: \(url.path)")
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
