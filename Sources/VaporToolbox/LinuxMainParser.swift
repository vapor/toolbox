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

/*
 // TODO:
 - allow declared TestClass Inheritors (for situations where a base TestClass is imported from another module)
 -
 */
import SwiftSyntax
import Foundation

public func syntaxTesting() throws {
//    try testModuleParsing(in: "/Users/loganwright/Desktop/test/Tests")
//    let modules = try loadModules(in: "/Users/loganwright/Desktop/test/Tests")
    let modules = try loadModules(in: "/Users/loganwright/Desktop/toolbox/Tests")
    print("LinuxMain:")
    print("\n\n")
    print(try modules.generateLinuxMain())
    print("")
//    let testSuite = try loadTestSuite(in: "/Users/loganwright/Desktop/test/Tests/AppTests")
//    let gatherer = try makeGatherer()
//    let testSuite = try gatherer.makeTestSuite()
//    logSuite(testSuite)
//    print(testSuite)
//    print("")
}

func makeGatherer() throws -> Gatherer {
    let file = "/Users/loganwright/Desktop/test/Tests/AppTests/NestedClassTests.swift"
    return try Gatherer.processFile(at: file)
//    let url = URL(fileURLWithPath: file)
//    let sourceFile = try SyntaxTreeParser.parse(url)
//    let gatherer = Gatherer()
//    gatherer.visit(sourceFile)
//    return gatherer
}

struct Module {
    let name: String
    // TODO: Protect Privately?
    let suite: TestSuite

    func simpleSuite() throws -> [(testCase: String, tests: [String])] {
        struct Holder {
            static var val: [(testCase: String, tests: [String])]? = nil
        }
        if let val = Holder.val { return val }

        var simple: [(testCase: String, tests: [String])] = []

        // simplify
        try suite.forEach { testCase, tests in
            let tests = tests.map { $0.identifier.description }
            let testCase = try testCase.flattenedName()

            // Can't have `extension Module.Module {` where testCase
            // and Module name are the same or compiler crashes
            let validTestCaseName: String
            if testCase == name {
                validTestCaseName = testCase
            } else {
                validTestCaseName = name + "." + testCase
            }
            simple.append((validTestCaseName, tests))
        }

        // alphabetical for consistency
        let val = simple.sorted { $0.testCase < $1.testCase }
        Holder.val = val
        return val
    }
}

/*
 import XCTest

 @testable import VaporToolboxTests

 extension VaporToolboxTests {
 static let __allTests = [
 ("testNothing", testNothing),
 ("testFail", testFail),
 ]
 }

 #if !os(macOS)
 public func __allTests() -> [XCTestCaseEntry] {
 return [
 testCase(VaporToolboxTests.__allTests),
 ]
 }

 var tests = [XCTestCaseEntry]()
 tests += __allTests()

 XCTMain(tests)
 #endif
 */


func loadModules(in testDirectory: String) throws -> [Module] {
    let testDirectory = testDirectory.finished(with: "/")
    guard isDirectory(in: testDirectory) else { throw "no test directory found" }
    let testModules = try findTestModules(in: testDirectory)
    return try testModules.map { moduleName in
        let moduleDirectory = testDirectory + moduleName
        let suite = try loadTestSuite(in: moduleDirectory)
        return Module(name: moduleName, suite: suite)
    }
}

func testModuleParsing(in testDirectory: String) throws {
    let testDirectory = testDirectory.finished(with: "/")
    guard isDirectory(in: testDirectory) else { throw "no test directory found" }
    let files = try findTestModules(in: testDirectory)

    print("Found subdirectories: \(files)")
    print("")
}

func isDirectory(in parentDirectory: String) -> Bool {
    let parentDirectory = parentDirectory.finished(with: "/")
    var isDir: ObjCBool = false
    let _ = FileManager.default.fileExists(atPath: parentDirectory, isDirectory: &isDir)
    return isDir.boolValue
}

func findTestModules(in directory: String) throws -> [String] {
    let directory = directory.finished(with: "/")
    return try FileManager.default
        .contentsOfDirectory(atPath: directory)
        .filter { isDirectory(in: directory + $0) }
        .filter { $0.hasSuffix("Tests") }
}

func loadTestSuite(in directory: String) throws -> TestSuite {
    let directory = directory.finished(with: "/")
    return try FileManager.default
        .contentsOfDirectory(atPath: directory)
        .filter { $0.hasSuffix(".swift") }
        .map { directory + $0 }
        .map(Gatherer.processFile)
        .merge()
        .makeTestSuite()
}

extension Module: CustomStringConvertible {
    var description: String {
        var desc = "\n"
        desc += "MODULE:\n\(name)\n"
        desc += "SUITE:\n"
        desc += suite.description
        return desc
    }
}

extension Dictionary: CustomStringConvertible where Key == ClassDeclSyntax, Value == Array<FunctionDeclSyntax> {
    var description: String {
        var desc = ""
        forEach { testCase, tests in
            let flattened = try? testCase.flattenedName()
            desc += "\(flattened ?? "<unable to flatten>")\n"
            tests.forEach { test in
                desc += "\t\(test.identifier)\n"
            }
        }
        return desc
    }
}

func logSuite(_ suite: TestSuite) {
    print(suite)
}
