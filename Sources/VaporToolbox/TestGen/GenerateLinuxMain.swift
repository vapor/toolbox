extension Array where Element == Module {
    func generateLinuxMain() -> String {
        var linuxMain = "import XCTest\n\n"

        // build imports
        linuxMain += map { "@testable import \($0.name)" } .joined(separator: "\n")
        linuxMain += "\n\n"

        // extension imports
        forEach { module in
            linuxMain += "// MARK: \(module.name)\n\n"
            linuxMain += module.generateAllTestsVariableCodeBlock()
            linuxMain += "\n\n"
        }

        linuxMain += generateLinuxTestImports()
        linuxMain += "\n\n"
        // return
        return linuxMain
    }

    private func generateLinuxTestImports() -> String {
        var block = "#if !os(macOS)\n"
        block += "public func __allTests() -> [XCTestCaseEntry] {\n"
        block += "\treturn [\n"
        forEach { module in
            block += "\t\t// \(module.name)\n"
            module.simplifiedSuite().forEach { (testCase, _) in
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
    func generateAllTestsVariableCodeBlock() -> String {
        return simplifiedSuite().map(generateBlockFor).joined(separator: "\n\n")
    }

    private func generateBlockFor(testCase: String, tests: [String]) -> String {
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
