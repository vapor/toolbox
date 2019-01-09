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

public func testtt() throws {
    let manifest = "/Users/loganwright/Desktop/yoooooo/Package.swift"
    let _ = try ManifestVisitor.processFile(at: manifest)
}
typealias SimplifiedTestSuite = [SimpleTestCase]

func dump(_ syntax: Syntax) {
    print("Type: \(type(of: syntax))")
    if let token = syntax as? TokenSyntax {
        print("Kind: \(token.tokenKind)")
    }
    print("Value:")
    print("\(syntax)")
}
/// To properly generate the file, we can't simply process
/// a single file, but rather need to process the
/// module (and ideally dependencies) in its entirety to
/// understand the file
/*
 Type: FunctionCallArgumentSyntax
 Value:

 dependencies: [
 // vapor web framework
 .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
 ],

 // NOTE Look into .label
 .label
 */

/*
 Type: ArrayExprSyntax
 Value:
 [
 // vapor web framework
 .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
 ]

 // NOTES
 `.elements`
 */

class ManifestVisitor: SyntaxVisitor {

    override func visitPre(_ node: Syntax) {
        defer { super.visitPre(node) }
        dump(node)
        print("***")
    }
//    override func visit(_ node: Syntax) {
//        defer { super.visit(node) }
//        print("Visited node: \n\(node)")
//        print("")
//    }

    override func visit(_ node: ClassDeclSyntax) {
        defer { super.visit(node) }
//        potentialTestCases.append(node)
    }

    override func visit(_ node: FunctionDeclSyntax) {
        defer { super.visit(node) }
//        guard node.looksLikeTestFunction else { return }
//        potentialTestFunctions.append(node)
    }
}

extension ManifestVisitor {
    static func processFile(at url: String) throws -> ManifestVisitor {
        let url = URL(fileURLWithPath: url)
        let sourceFile = try SyntaxTreeParser.parse(url)
        let visitor = ManifestVisitor()
        visitor.visit(sourceFile)
        return visitor
    }
}
//
//extension Gatherer {
//    fileprivate convenience init(potentialTestFunctions: [FunctionDeclSyntax], potentialTestCases: [ClassDeclSyntax]) {
//        fatalError()
//    }
//}
//
//extension Array where Element == Gatherer {
//    func merge() -> Gatherer {
//        fatalError()
//    }
//}
//
//extension Gatherer {
//    private func testCases() -> [ClassDeclSyntax] {
//        fatalError()
//    }
//
//    private func tests() -> [FunctionDeclSyntax] {
//        fatalError()
//    }
//
//    func makeTestSuite() throws -> TestSuite {
//        fatalError()
//    }
//}
