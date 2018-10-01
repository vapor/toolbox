extension Array where Element == Module {
    func generateLinuxMain() throws -> String {
        var linuxMain = "import XCTest\n\n"

        // build imports
        linuxMain += map { "@testable import \($0.name)" } .joined(separator: "\n")
        linuxMain += "\n\n"

        // extension imports
        try forEach { module in
            linuxMain += "// MARK: \(module.name)\n\n"
            linuxMain += try module.generateAllTestsVariableCodeBlock()
            linuxMain += "\n\n"
        }

        linuxMain += try generateLinuxTestImports()
        linuxMain += "\n\n"
        // return
        return linuxMain
    }

    private func generateLinuxTestImports() throws -> String {
        var block = "#if !os(macOS)\n"
        block += "public func __allTests() -> [XCTestCaseEntry] {\n"
        block += "\treturn [\n"
        try forEach { module in
            try module.simpleSuite().forEach { (testCase, _) in
//                let testCase = try testCase.flattenedName()
//                // If class name is same as module name, you can't use `extension Name.Name` or compiler will fail
//                let extensionName: String
//                if testCase == module.name {
//                    extensionName = testCase
//                } else {
//                    extensionName = module.name + "." + testCase
//                }
                block += "\t\ttestCase(\(testCase).__allTests),\n"
            }
        }
        block += "\t]\n"
        block += "}\n\n"
        block += "let tests = __allTests()\n"
        block += "XCTMain(tests)\n"
        block += "#endif\n\n"
        return block
    }
}

import SwiftSyntax
extension Module {
    func generateAllTestsVariableCodeBlock() throws -> String {
        return try simpleSuite().map(generateBlockFor).joined(separator: "\n\n")
    }

    private func generateBlockFor(testCase: String, tests: [String]) throws -> String {
        var block = "extension \(testCase) {\n"
        block += "\t"
        block += "static let __allTests = [\n"
        tests.forEach {
            block += "\t\t(\"\($0)\", \($0)),\n"
        }
        block += "\t]\n"
        block += "}"
        return block
    }
}
