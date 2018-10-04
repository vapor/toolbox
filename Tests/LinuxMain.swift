import XCTest

@testable import LinuxTestsGenerationTests
@testable import GenerationTestFilesTests

// MARK: LinuxTestsGenerationTests

extension LinuxTestsGenerationTests.VaporToolboxTests0 {
	static let __allVaporToolboxTests0Tests = [
		("testNothing", testNothing),
	]
}

// MARK: GenerationTestFilesTests

extension GenerationTestFilesTests.A.B {
	static let __allABTests = [
		("testIsValid", testIsValid),
	]
}

extension GenerationTestFilesTests.AlsoSimple {
	static let __allAlsoSimpleTests = [
		("testValid", testValid),
	]
}

extension GenerationTestFilesTests.Case {
	static let __allCaseTests = [
		("testValid", testValid),
		("testValidThrows", testValidThrows),
		("testInExtension", testInExtension),
	]
}

extension GenerationTestFilesTests.D.C {
	static let __allDCTests = [
		("testValid", testValid),
	]
}

extension GenerationTestFilesTests.DoubleInherited {
	static let __allDoubleInheritedTests = [
		("testAnotherAddition", testAnotherAddition),
	]
}

extension GenerationTestFilesTests.Inherited {
	static let __allInheritedTests = [
		("testAddition", testAddition),
	]
}

extension GenerationTestFilesTests.NotTestClass.NestedCase {
	static let __allNotTestClassNestedCaseTests = [
		("testValid", testValid),
		("testNestedExtension", testNestedExtension),
	]
}

extension GenerationTestFilesTests.NotTestClass.NestedInExtensionCase {
	static let __allNotTestClassNestedInExtensionCaseTests = [
		("testValid", testValid),
	]
}

extension GenerationTestFilesTests.NotTestStruct.NestedCase {
	static let __allNotTestStructNestedCaseTests = [
		("testValid", testValid),
	]
}

extension GenerationTestFilesTests.NotTestStruct.NestedInExtensionCase {
	static let __allNotTestStructNestedInExtensionCaseTests = [
		("testValid", testValid),
	]
}

extension GenerationTestFilesTests.One.Two.Three {
	static let __allOneTwoThreeTests = [
		("testValid", testValid),
		("testAlsoValid", testAlsoValid),
	]
}

extension GenerationTestFilesTests.SimpleTests {
	static let __allSimpleTestsTests = [
		("testValid", testValid),
	]
}

extension GenerationTestFilesTests.VaporToolboxTests0 {
	static let __allVaporToolboxTests0Tests = [
		("testNothing", testNothing),
		("testFail", testFail),
	]
}

// MARK: Test Runner

#if !os(macOS)
public func __buildTestEntries() -> [XCTestCaseEntry] {
	return [
		// LinuxTestsGenerationTests
		testCase(VaporToolboxTests0.__allVaporToolboxTests0Tests),
		// GenerationTestFilesTests
		testCase(A.B.__allABTests),
		testCase(AlsoSimple.__allAlsoSimpleTests),
		testCase(Case.__allCaseTests),
		testCase(D.C.__allDCTests),
		testCase(DoubleInherited.__allDoubleInheritedTests),
		testCase(Inherited.__allInheritedTests),
		testCase(NotTestClass.NestedCase.__allNotTestClassNestedCaseTests),
		testCase(NotTestClass.NestedInExtensionCase.__allNotTestClassNestedInExtensionCaseTests),
		testCase(NotTestStruct.NestedCase.__allNotTestStructNestedCaseTests),
		testCase(NotTestStruct.NestedInExtensionCase.__allNotTestStructNestedInExtensionCaseTests),
		testCase(One.Two.Three.__allOneTwoThreeTests),
		testCase(SimpleTests.__allSimpleTestsTests),
		testCase(VaporToolboxTests0.__allVaporToolboxTests0Tests),
	]
}

let tests = __buildTestEntries()
XCTMain(tests)
#endif

