import XCTest

@testable import LinuxTestsGenerationTests

// MARK: LinuxTestsGenerationTests

extension LinuxTestsGenerationTests.GenerationTests {
	static let __allGenerationTestsTests = [
		("testNothing", testNothing),
	]
}

// MARK: Test Runner

#if !os(macOS)
public func __buildTestEntries() -> [XCTestCaseEntry] {
	return [
		// LinuxTestsGenerationTests
		testCase(GenerationTests.__allGenerationTestsTests),
	]
}

let tests = __buildTestEntries()
XCTMain(tests)
#endif

