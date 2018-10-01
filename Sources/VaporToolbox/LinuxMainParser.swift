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

public func syntaxTesting() throws {
    let gatherer = try makeGatherer()
    try buildInheritanceTree(with: gatherer)
}


//func testSimple() throws {
//    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/NestedClassTests.swift"
//    let url = URL(fileURLWithPath: file)
//    let sourceFile = try SyntaxTreeParser.parse(url)
//    let gatherer = ClassGatherer()
//    gatherer.visit(sourceFile)
//    print("")
//}

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
//    let writer = Writer(suite: testSuite)
//    writer.write()
    print("")
}

func asdf() {
    let ex = ExtensionDeclSyntax { (builder) in

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


