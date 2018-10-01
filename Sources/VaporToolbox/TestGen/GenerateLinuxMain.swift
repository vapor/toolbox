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
            try module.suite.keys.forEach { testCase in
                let testCase = try testCase.flattenedName()
                // If class name is same as module name, you can't use `extension Name.Name` or compiler will fail
                let extensionName: String
                if testCase == module.name {
                    extensionName = testCase
                } else {
                    extensionName = module.name + "." + testCase
                }
                block += "\t\ttestCase(\(extensionName).__allTests),\n"
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
        return try suite.map(generateBlockFor).joined(separator: "\n\n")
    }

    private func generateBlockFor(testCase: ClassDeclSyntax, tests: [FunctionDeclSyntax]) throws -> String {
        let testCase = try testCase.flattenedName()

        // If class name is same as module name, you can't use `extension Name.Name` or compiler will fail
        let extensionName: String
        if testCase == name {
            extensionName = testCase
        } else {
            extensionName = name + "." + testCase
        }
        var block = "extension \(extensionName) {\n"
        block += "\t"
        block += "static let __allTests = [\n"
        tests.map { "(\"\($0.identifier)\", \($0.identifier))" }.forEach { test in
            block += "\t\t\(test),\n"
        }
        block += "\t]\n"
        block += "}"
        return block
    }
}
