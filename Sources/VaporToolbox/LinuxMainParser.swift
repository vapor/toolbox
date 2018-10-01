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
    let modules = try loadModules(in: "/Users/loganwright/Desktop/test/Tests")
//    let modules = try loadModules(in: "/Users/loganwright/Desktop/toolbox/Tests")
    print("LinuxMain:")
    print("\n\n")
    print(modules.generateLinuxMain())
    print("")
}

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
        desc += simplifiedSuite().description
        return desc
    }
}
