/*
 EDGE CASE
 - inherit from class that inherits from xctest
 - test cases declared in an extension
 - test functions declared in non xctest class
 - test declared in extension of class that isn't valid xctestcase

 NICE TO HAVE
 - remove existing allTests if it exists
 */

import SwiftSyntax

public func syntaxTesting() throws {
    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/AppTests.swift"
    let url = URL(fileURLWithPath: file)
    let sourceFile = try SyntaxTreeParser.parse(url)
//    Visitor().visit(sourceFile)
    let gatherer = TestFunctionGatherer()
    gatherer.visit(sourceFile)
    print(gatherer.testFunctions)
//    Visitor().visit(sourceFile)
//    TestFunctionLoader().visit(sourceFile)
    print(sourceFile)
    print("")
}

func incrementor() throws {
    let file = "/Users/loganwright/Desktop/foo/Test.swift"
    let url = URL(fileURLWithPath: file)
    let sourceFile = try SyntaxTreeParser.parse(url)
//    print(sourceFile.statements)
    let incremented = AddOneToIntegerLiterals().visit(sourceFile)
    print(incremented)
    print("")
}


import SwiftSyntax
import Foundation

/// AddOneToIntegerLiterals will visit each token in the Syntax tree, and
/// (if it is an integer literal token) add 1 to the integer and return the
/// new integer literal token.
class AddOneToIntegerLiterals: SyntaxRewriter {
    override func visit(_ token: TokenSyntax) -> Syntax {
        // Only transform integer literals.
        guard case .integerLiteral(let text) = token.tokenKind else {
            return token
        }

        // Remove underscores from the original text.
        let integerText = String(text.filter { ("0"..."9").contains($0) })

        // Parse out the integer.
        let int = Int(integerText)!

        // Return a new integer literal token with `int + 1` as its text.
        return token.withKind(.integerLiteral("\(int + 1)"))
    }
}


extension FunctionDeclSyntax {
    var isTestFunction: Bool {
        print(self.identifier.text)
        // SwiftSyntax.SourceFileSyntax -- use to discount top level functions
        // SwiftSyntax.ExtensionDeclSyntax -- declared in extension, OK
        // SwiftSyntax.ClassDeclSyntax -- declared in class, OK
        print("nno. of parents: \(self.countParents())")
        print("tree: ")
        let yes = self.inheritanceTree().contains(where: { $0 is ExtensionDeclSyntax || $0 is ClassDeclSyntax})
        print("SHOULD INCLUDE: \(yes)")
//        let tree = inheritanceTree().map { "\($0)" }.joined(separator: "\n")
//        print(tree)
//        print(self.parent)
        print("")
        guard
            // all tests MUST begin w/ 'test' as prefix
            identifier.text.hasPrefix("test"),
            // all tests MUST take NO arguments
            signature.input.parameterList.count == 0,
            // all tests MUST have no output
            signature.output == nil,
            // all tests MUST be declared w/in a class,
            // or an extension
            inheritanceTree().containsClassOrExtension
            else { return false }
        return true
    }
}

extension Array where Element == Syntax {
    var containsClassOrExtension: Bool {
        return contains { $0 is ExtensionDeclSyntax || $0 is ClassDeclSyntax}
    }
}

extension Syntax {
    func inheritanceTree() -> [Syntax] {
        guard let parent = parent else { return [self] }
        return [self] + parent.inheritanceTree()
    }

    func countParents() -> Int {
        guard let parent = self.parent else { return 0 }
        return parent.countParents() + 1
    }

    func typedTree() -> [Syntax.Type] {
        guard let parent = self.parent else { return [type(of: self)] }
        return [type(of: parent)] + parent.typedTree()
    }
}
/*
 TEST RESULTS
 - class name
 - inheritance class
    • if XCTestCase – good to go
    • if class that inherits XCTest – good to go
 */

struct Object {
    let name: String
    let inheritance: String?
}

class TestFunctionGatherer: SyntaxVisitor {

    var testFunctions: [String] = []

    private var inClass = false
    private var inExtension = false

    override func visit(_ node: ClassDeclSyntax) {
        inClass = true
        defer { inClass = false }
        super.visit(node)
//        let inheritance = node.inheritanceClause!
//        let collection = inheritance.inheritedTypeCollection
//        var iterator = collection.makeIterator()
//        while let next = iterator.next() {
//            print(next.typeName)
//            print("")
//        }
//        print(inheritance.inheritedTypeCollection)
//
//        print(node.inheritanceClause)
//        print(node)
//        print("")
    }

    override func visit(_ node: ExtensionDeclSyntax) {
        inExtension = true
        defer { inExtension = false }
        super.visit(node)
    }

    override func visit(_ node: FunctionDeclSyntax) {
        guard node.isTestFunction else { return }
        testFunctions.append(node.identifier.text)
    }
}

class Visitor: SyntaxVisitor {
    override func visit(_ node: FunctionDeclSyntax) {
//        print("**\(#line): \(node)")
        print(node.identifier)
        print(node.signature)
        let sig = node.signature
        print(sig.input)
        print(sig.input.parameterList.count)
        print(sig.output)
        print(sig.throwsOrRethrowsKeyword)
//        print(node.attributes)
//        print(node.funcKeyword)
//        print(node.)
        print("")
    }

    override func visit(_ node: FunctionParameterListSyntax) {
        print(node)
        print("")
    }

//    override func visit(_ node: FunctionCallArgumentListSyntax) {
//        print(node)
//        print("")
//    }
//    override func visit(_ node: FunctionCallArgumentSyntax) {
//        print(node)
//        print("")
//    }

    override func visit(_ node: FunctionSignatureSyntax) {
//        print("**\(#line): \(node)")
    }
}

class TestFunctionLoader: SyntaxRewriter {
    var functions: [String] = []
    
    override func visit(_ token: TokenSyntax) -> Syntax {
//        print("Got token: \(token)")
//        print("Got type : \(token.tokenKind)")
        return token

    }
}
