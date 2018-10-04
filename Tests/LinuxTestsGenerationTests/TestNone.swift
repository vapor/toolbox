import XCTest
@testable import LinuxTestsGeneration

final class VaporToolboxTests0: XCTestCase {
    func testNothing() throws {
        let directory = testsDirectory()
        let linuxMain = try LinuxMain(testsDirectory: directory, ignoring: ["LinuxTestsGenerationTests"])
        XCTAssertEqual(linuxMain.imports, expectedImports)
        XCTAssertEqual(linuxMain.extensions, expectedExtensions)
        XCTAssertEqual(linuxMain.testRunner, expectedTestRunner)
    }
}

let expectedImports = """
import XCTest

@testable import GenerationTestFilesTests


"""

let expectedExtensions = """
// MARK: GenerationTestFilesTests

extension GenerationTestFilesTests.A.B {
\tstatic let __allABTests = [
\t\t("testIsValid", testIsValid),
\t]
}

extension GenerationTestFilesTests.AlsoSimple {
\tstatic let __allAlsoSimpleTests = [
\t\t("testValid", testValid),
\t]
}

extension GenerationTestFilesTests.Case {
\tstatic let __allCaseTests = [
\t\t("testValid", testValid),
\t\t("testValidThrows", testValidThrows),
\t\t("testInExtension", testInExtension),
\t]
}

extension GenerationTestFilesTests.D.C {
\tstatic let __allDCTests = [
\t\t("testValid", testValid),
\t]
}

extension GenerationTestFilesTests.DoubleInherited {
\tstatic let __allDoubleInheritedTests = [
\t\t("testAnotherAddition", testAnotherAddition),
\t]
}

extension GenerationTestFilesTests.Inherited {
\tstatic let __allInheritedTests = [
\t\t("testAddition", testAddition),
\t]
}

extension GenerationTestFilesTests.NotTestClass.NestedCase {
\tstatic let __allNotTestClassNestedCaseTests = [
\t\t("testValid", testValid),
\t\t("testNestedExtension", testNestedExtension),
\t]
}

extension GenerationTestFilesTests.NotTestClass.NestedInExtensionCase {
\tstatic let __allNotTestClassNestedInExtensionCaseTests = [
\t\t("testValid", testValid),
\t]
}

extension GenerationTestFilesTests.NotTestStruct.NestedCase {
\tstatic let __allNotTestStructNestedCaseTests = [
\t\t("testValid", testValid),
\t]
}

extension GenerationTestFilesTests.NotTestStruct.NestedInExtensionCase {
\tstatic let __allNotTestStructNestedInExtensionCaseTests = [
\t\t("testValid", testValid),
\t]
}

extension GenerationTestFilesTests.One.Two.Three {
\tstatic let __allOneTwoThreeTests = [
\t\t("testValid", testValid),
\t\t("testAlsoValid", testAlsoValid),
\t]
}

extension GenerationTestFilesTests.SimpleTests {
\tstatic let __allSimpleTestsTests = [
\t\t("testValid", testValid),
\t]
}

extension GenerationTestFilesTests.VaporToolboxTests0 {
\tstatic let __allVaporToolboxTests0Tests = [
\t\t("testNothing", testNothing),
\t\t("testFail", testFail),
\t]
}


"""

let expectedTestRunner = """
// MARK: Test Runner

#if !os(macOS)
public func __buildTestEntries() -> [XCTestCaseEntry] {
\treturn [
\t\t// GenerationTestFilesTests
\t\ttestCase(A.B.__allABTests),
\t\ttestCase(AlsoSimple.__allAlsoSimpleTests),
\t\ttestCase(Case.__allCaseTests),
\t\ttestCase(D.C.__allDCTests),
\t\ttestCase(DoubleInherited.__allDoubleInheritedTests),
\t\ttestCase(Inherited.__allInheritedTests),
\t\ttestCase(NotTestClass.NestedCase.__allNotTestClassNestedCaseTests),
\t\ttestCase(NotTestClass.NestedInExtensionCase.__allNotTestClassNestedInExtensionCaseTests),
\t\ttestCase(NotTestStruct.NestedCase.__allNotTestStructNestedCaseTests),
\t\ttestCase(NotTestStruct.NestedInExtensionCase.__allNotTestStructNestedInExtensionCaseTests),
\t\ttestCase(One.Two.Three.__allOneTwoThreeTests),
\t\ttestCase(SimpleTests.__allSimpleTestsTests),
\t\ttestCase(VaporToolboxTests0.__allVaporToolboxTests0Tests),
\t]
}

let tests = __buildTestEntries()
XCTMain(tests)
#endif


"""
