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
            try module.simplifiedSuite().forEach { (testCase, _) in
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

extension Module {
    func generateAllTestsVariableCodeBlock() throws -> String {
        return try simplifiedSuite().map(generateBlockFor).joined(separator: "\n\n")
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
