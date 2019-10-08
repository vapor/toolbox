import Foundation
import Globals

/// A simple structure to model out the LinuxMain
public struct LinuxMain {
    public let imports: String
    public let extensions: String
    public let testRunner: String

    let testsDirectory: String
    let ignoredDirectories: [String]

    public var filePath: String {
        return testsDirectory + "LinuxMain.swift"
    }
    var fileContents: String {
        return imports + extensions + testRunner
    }

    public init(testsDirectory: String, ignoring ignoredDirectories: [String] = []) throws {
        let modules = try loadModules(in: testsDirectory, ignoring: ignoredDirectories)
        self.imports = modules.imports()
        self.extensions = modules.extensions()
        self.testRunner = modules.testRunner()

        self.testsDirectory = testsDirectory.trailingSlash
        self.ignoredDirectories = ignoredDirectories
    }

    public func write() throws {
        try fileContents.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
}

extension LinuxMain: CustomStringConvertible {
    public var description: String {
        return fileContents
    }
}

extension Array where Element == Module {
    fileprivate func imports() -> String {
        var imports = ""
        imports += "import XCTest\n\n"
        forEach { module in
            imports += "@testable import \(module.name)\n"
        }
        imports += "\n"
        return imports
    }

    fileprivate func extensions() -> String {
        var extens = ""
        forEach { module in
            extens += "// MARK: \(module.name)\n\n"
            extens += module.generateExtensions()
            extens += "\n\n"
        }
        return extens
    }

    fileprivate func testRunner() -> String {
        var block = "// MARK: Test Runner\n\n"
        block += "#if !os(macOS)\n"
        block += "public func __buildTestEntries() -> [XCTestCaseEntry] {\n"
        block += "\treturn [\n"
        forEach { module in
            block += "\t\t// \(module.name)\n"
            module.simplified.forEach { testCase in
                block += "\t\ttestCase(\(testCase.name).\(testCase.testsVariableName)),\n"
            }
        }
        block += "\t]\n"
        block += "}\n\n"
        block += "let tests = __buildTestEntries()\n"
        block += "XCTMain(tests)\n"
        block += "#endif\n\n"
        return block
    }
}

extension Module {
    fileprivate func generateExtensions() -> String {
        return simplified.map { $0.generateExtension() } .joined(separator: "\n\n")
    }
}

extension SimpleTestCase {
    fileprivate func generateExtension() -> String {
        var block = "extension \(extensionName) {\n"
        block += "\t"
        block += "static let \(testsVariableName) = [\n"
        tests.forEach {
            block += "\t\t(\"\($0)\", \($0)),\n"
        }
        block += "\t]\n"
        block += "}"
        return block
    }
}

private func loadModules(in testDirectory: String, ignoring: [String]) throws -> [Module] {
    let testDirectory = testDirectory.trailingSlash
    guard isDirectory(in: testDirectory) else { throw "no test directory found" }
    let testModules = try findTestModules(in: testDirectory)
        .filter { !ignoring.contains($0) }
    return try testModules.map { moduleName in
        let moduleDirectory = testDirectory + moduleName
        let suite = try loadTestSuite(in: moduleDirectory)
        return Module(name: moduleName, suite: suite)
    }
}

private func isDirectory(in parentDirectory: String) -> Bool {
    let parentDirectory = parentDirectory.trailingSlash
    var isDir: ObjCBool = false
    let _ = FileManager.default.fileExists(atPath: parentDirectory, isDirectory: &isDir)
    return isDir.boolValue
}

private func findTestModules(in directory: String) throws -> [String] {
    let directory = directory.trailingSlash
    return try FileManager.default
        .contentsOfDirectory(atPath: directory)
        .filter { isDirectory(in: directory + $0) }
        .filter { $0.hasSuffix("Tests") }
}

private func loadTestSuite(in directory: String) throws -> TestSuite {
    let directory = directory.trailingSlash
    return try FileManager.default
        .contentsOfDirectory(atPath: directory)
        .filter { $0.hasSuffix(".swift") }
        .map { directory + $0 }
        .map(Gatherer.processFile)
        .merge()
        .makeTestSuite()
}
