//
//  Scaffolding.swift
//  VaporToolbox
//
//  Created by Logan Wright on 9/21/18.
//

import SwiftSyntax

public func syntaxTesting() throws {
    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/AppTests.swift"
    let url = URL(fileURLWithPath: file)
    let sourceFile = try SyntaxTreeParser.parse(url)
//    print(sourceFile.statements)
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
    print(sourceFile.statements)
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
        guard
            // all tests MUST begin w/ 'test' as prefix
            identifier.text.hasPrefix("test"),
            // all tests MUST take NO arguments
            signature.input.parameterList.count == 0,
            // all tests MUST have no output
            signature.output == nil
            else { return false }
        return true
    }
}

class TestFunctionGatherer: SyntaxVisitor {
    var testFunctions: [String] = []

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
