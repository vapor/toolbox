/*
 EDGE CASE
 - MULTI-FILE - inheritance, nesting, extensions
 - inherit from class that inherits from xctest
 - test cases declared in an extension
 - test functions declared in non xctest class
 - test declared in extension of class that isn't valid xctestcase
 - Nested Class/Struct/Extension Needs to Have `Nested.Class` for example

 - Technically, we can't generate the source code we need to from here
 - private keyword must discount tests
 NICE TO HAVE
 - remove existing allTests if it exists
 */

/*
 - Find Test Targets in Tests/ Folder
 - Parse test targets into files:
 {
 - Module: String
 - TestSuite: [ClassDeclSyntax: [[FunctionDeclSyntax]]
 }
 - Generate LinuxMain
 - Run Swift Test
 - Run Docker
 */
import SwiftSyntax
import Foundation

class ManifestParser: SyntaxVisitor {
    override func visitPre(_ node: Syntax) {
        defer { super.visitPre(node) }
//        guard let argumentSyntax = node as? FunctionCallArgumentSyntax else { return }
        print("Visited: \(type(of: node))")
        print("Found:\n\(node)")
        print("")
    }

    override func visit(_ node: FunctionCallArgumentSyntax) {
        defer { super.visit(node) }
        print("")
    }
}

func testManifestParser() throws {
    let file = "/Users/loganwright/Desktop/test/Package.swift"
    let url = URL(fileURLWithPath: file)
    let sourceFile = try SyntaxTreeParser.parse(url)
    ManifestParser().visit(sourceFile)
}

public func syntaxTesting() throws {
    try testManifestParser()
    try testWriter()
    let gatherer = try makeGatherer()
    try buildInheritanceTree(with: gatherer)
//    try testGathering()
//    try testFunctionGathering()
//    try testClassGathering()

//    try testGathering()
//    try testSimple()
//    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/TestCases.swift"
//    let url = URL(fileURLWithPath: file)
//    let sourceFile = try SyntaxTreeParser.parse(url)
//    let gatherer = TestFunctionGatherer()
//    gatherer.visit(sourceFile)
//    print(gatherer.testFunctions)
//    //    Visitor().visit(sourceFile)
//    //    TestFunctionLoader().visit(sourceFile)
//    print(sourceFile)
//    print("")
}


func testSimple() throws {
    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/NestedClassTests.swift"
    let url = URL(fileURLWithPath: file)
    let sourceFile = try SyntaxTreeParser.parse(url)
    let gatherer = ClassGatherer()
    gatherer.visit(sourceFile)
    print("")
}

//func testGathering() throws {
//    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/NestedClassTests.swift"
//    let url = URL(fileURLWithPath: file)
//    let sourceFile = try SyntaxTreeParser.parse(url)
//    let gatherer = Gatherer()
//    gatherer.visit(sourceFile)
//    print("Found classes: ")
//    print(try gatherer.potentialTestCases.filter { $0.inheritsDirectlyFromXCTestCase }.map { try $0.flattenedName() }.joined(separator: "\n"))
//    print("Found potential tests: ")
////    print(gatherer.potentialTestFunctions.map { $0.identifier.text }.joined(separator: "\n"))
//    print("")
//}

// TODO: Temporary

func XCTAssert(_ bool: Bool, msg: String) {
    if bool { return }
    print(" [ERRROROROREOREOREOREORE] \(msg)")
}

func makeGatherer() throws -> Gatherer {
    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/NestedClassTests.swift"
    let url = URL(fileURLWithPath: file)
    let sourceFile = try SyntaxTreeParser.parse(url)
    let gatherer = Gatherer()
    gatherer.visit(sourceFile)
    return gatherer
}

//func testClassGathering() throws {
//    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/NestedClassTests.swift"
//    let url = URL(fileURLWithPath: file)
//    let sourceFile = try SyntaxTreeParser.parse(url)
//    let gatherer = Gatherer()
//    gatherer.visit(sourceFile)
//    let foundClasses = try gatherer.potentialTestCases.map { try $0.flattenedName() }
//    let expectation = [
//        "A",
//        "A.B",
//        "A.C",
//        "A.B.C",
//        "D.C"
//    ]
//    XCTAssert(foundClasses == expectation, msg: "Parsing nested classes didn't work as expected.")
//}

//func testFunctionGathering() throws {
//    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/FunctionTestCases.swift"
//    let url = URL(fileURLWithPath: file)
//    let sourceFile = try SyntaxTreeParser.parse(url)
//    let gatherer = Gatherer()
//    gatherer.visit(sourceFile)
//    print("Found classes: ")
//    print(try gatherer.potentialTestCases.map { try $0.flattenedName() }.joined(separator: "\n"))
//    print("Found potential tests: ")
////    print(gatherer.potentialTestFunctions.map { $0.identifier.text }.joined(separator: "\n"))
//    print("")
//}

func parseModule() {

}


/*
 ALL FUNCTIONS
 - FUNCTION NAME
 - PARENT NAME

 ALL CLASSES
 - NAME
 - INHERITANCE NAME
 // if XCTestCase.. ok, if not, see if class exists in our tree
 */

/*

 */

//struct TestClass {
//    let parentClass: String
//}
//struct TestFunction {
//    let parentClass: String
//    let functionName: String
//}

func buildInheritanceTree(with gatherer: Gatherer) throws {
//    let foundCases = try gatherer.testCases()
//    print("Cases: ")
//    print(try foundCases.map { try $0.flattenedName() } .joined(separator: "\n"))
//    let foundTests = try gatherer.tests()
//    print("Tests: ")
//    print(foundTests.map { $0.identifier.description } .joined(separator: "\n"))
//    print("")

    let testSuite = try gatherer.makeTestSuite()
//    print("Got testSuite: \n\(testSuite)")
    let writer = Writer(suite: testSuite)
    writer.write()
    print("")
}

func asdf() {
    let ex = ExtensionDeclSyntax { (builder) in

    }
}

extension Syntax {
    fileprivate func parentTreeContains(_ cds: ClassDeclSyntax) -> Bool {
        guard let parent = parent else { return false }
        if let parent = parent as? ClassDeclSyntax, parent == cds { return true }
        else { return parent.parentTreeContains(cds) }
    }
}

extension Array where Element == Syntax {
    var containsClassOrExtension: Bool {
        return contains { $0 is ExtensionDeclSyntax || $0 is ClassDeclSyntax}
    }
}

/*
 FILE PARSE RESULTS
 CLASS:
    - Name
    - InheritedFrom
    - ValidTestCases: [FUNCTION]
 FUNCTION:
    - Name
    - DeclaredWithin (Extension, Class)

 */

/*
 TEST RESULTS
 - class name
 - inheritance class
 • if XCTestCase – good to go
 • if class that inherits XCTest – good to go
 */

/*
 Is a class a testcase?
 - is it a class?
 - does it inherit XCTestCase
 */

struct Object {
    let name: String
    let inheritance: String?
}

class ClassGatherer: SyntaxVisitor {
    var testFunctions: [String] = []
    var classes: [ClassDeclSyntax] = []
    override func visit(_ node: ClassDeclSyntax) {
        print(node.identifier.text)
        let flattened = try! node.flattenedName()
        print(flattened)
        print("")
        super.visit(node)
    }

    override func visit(_ node: FunctionDeclSyntax) {
        guard node.looksLikeTestFunction else { return }
        testFunctions.append(node.identifier.text)
    }
}

extension Gatherer {
    // WARN: Need to use strings, not ClassDeclSyntax objects
    // because in other files, they are not directly linked
    func directXCTestInheritors() -> [ClassDeclSyntax] {
        fatalError("")
    }
}

extension ExtensionDeclSyntax {
    var extendedTypeName: String {
        return extendedType.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class TestFunctionGatherer: SyntaxVisitor {

    var testFunctions: [String] = []

    override func visit(_ node: ClassDeclSyntax) {
        print(node.identifier.text)
        print("")
        let inheritance = node.inheritanceClause
        print(inheritance)
        let collection = inheritance?.inheritedTypeCollection
        var iterator = collection?.makeIterator()
        while let next = iterator?.next() {
            print(next.typeName)
            print("")
        }
        print(inheritance?.inheritedTypeCollection)

        print(node.inheritanceClause)
        print(node)
        print("")
        super.visit(node)
    }

    override func visit(_ node: FunctionDeclSyntax) {
        guard node.looksLikeTestFunction else { return }
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

    override func visitPre(_ node: Syntax) {
        print("Got node: \(node)")
        super.visitPre(node)
    }
    override func visit(_ token: TokenSyntax) -> Syntax {

        return token
    }
}

func testWriter() throws {
    return
//    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/Empty.swift"
//    let url = URL(fileURLWithPath: file)
//    let sourceFile = try SyntaxTreeParser.parse(url)
//    print(sourceFile)
//    let writer = Writer()
//    let foo = writer.visit(sourceFile)
//    print(foo)
//    print("")
}

typealias TestSuite = [ClassDeclSyntax: [FunctionDeclSyntax]]
