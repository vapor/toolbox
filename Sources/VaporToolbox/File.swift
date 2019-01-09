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
class ManifestVisitor: SyntaxVisitor {
    fileprivate private(set) var potentialTestCases: [ClassDeclSyntax] = []
    fileprivate private(set) var potentialTestFunctions: [FunctionDeclSyntax] = []
    fileprivate var _testSuite: TestSuite? = nil

    override func visit(_ node: ClassDeclSyntax) {
        defer { super.visit(node) }
        potentialTestCases.append(node)
    }

    override func visit(_ node: FunctionDeclSyntax) {
        defer { super.visit(node) }
//        guard node.looksLikeTestFunction else { return }
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
        fatalError()
    }
}

extension Array where Element == Gatherer {
    func merge() -> Gatherer {
        fatalError()
    }
}

extension Gatherer {
    private func testCases() -> [ClassDeclSyntax] {
        fatalError()
    }

    private func tests() -> [FunctionDeclSyntax] {
        fatalError()
    }

    func makeTestSuite() throws -> TestSuite {
        fatalError()
    }
}
