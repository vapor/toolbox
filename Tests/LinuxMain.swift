import XCTest

@testable import VaporToolboxTests

// MARK: VaporToolboxTests

extension VaporToolboxTests.VaporToolboxTests0 {
	static let __allVaporToolboxTests0Tests = [
		("testNothing", testNothing),
		("testFail", testFail),
	]
}

// MARK: Test Runner

#if !os(macOS)
public func __buildTestEntries() -> [XCTestCaseEntry] {
	return [
		// VaporToolboxTests
		testCase(VaporToolboxTests0.__allVaporToolboxTests0Tests),
	]
}

let tests = __buildTestEntries()
XCTMain(tests)
#endif

