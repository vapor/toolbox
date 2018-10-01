struct LinuxMain {
    // TODO:
    // - ignorable directories
    static func generate(fromTestsDirectory testsDirectory: String) throws -> String {
        fatalError()
    }
}

extension Array where Element == Module {
    func generateLinuxMain() -> String {
        var linuxMain = ""

        // build imports
        linuxMain += imports()

        // extensions
        linuxMain += extensions()

        // test runner
        linuxMain += testRunner()

        // return
        return linuxMain
    }

    private func imports() -> String {
        var imports = ""
        imports += "import XCTest\n\n"
        forEach { module in
            imports += "@testable import \(module.name)\n"
        }
        imports += "\n"
        return imports
    }

    private func extensions() -> String {
        var extens = ""
        forEach { module in
            extens += "// MARK: \(module.name)\n\n"
            extens += module.generateExtensions()
            extens += "\n\n"
        }
        return extens
    }

    private func testRunner() -> String {
        var block = "// MARK: Test Runner"
        block += "#if !os(macOS)\n"
        block += "public func __allTests() -> [XCTestCaseEntry] {\n"
        block += "\treturn [\n"
        forEach { module in
            block += "\t\t// \(module.name)\n"
            module.simplified.forEach { testCase in
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
    func generateExtensions() -> String {
        return simplified.map { $0.generateExtension() } .joined(separator: "\n\n")
    }
}

extension SimpleTestCase {
    fileprivate func generateExtension() -> String {
        var block = "extension \(name) {\n"
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

