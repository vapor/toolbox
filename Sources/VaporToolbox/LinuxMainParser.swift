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

/*
 // TODO: Critical
 Upon generating __allTests, existing test declarations in XCTTestManifests will interfere with these declarations
 Look for and delete these older files
 */

import SwiftSyntax
import Foundation

public func syntaxTesting() throws {
    let linuxMain = try LinuxMain(testsDirectory: "/Users/loganwright/Desktop/test/Tests")
//    let modules = try loadModules(in: "/Users/loganwright/Desktop/toolbox/Tests")
    try linuxMain.write()
    print("LinuxMain:")
    print("\n\n************")
    print(linuxMain)
    print("n************")
}

extension Module: CustomStringConvertible {
    var description: String {
        var desc = "\n"
        desc += "MODULE:\n\(name)\n"
        desc += "SUITE:\n"
        desc += simplified.description
        return desc
    }
}
