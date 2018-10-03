import App
import XCTest

// test that a class inheriting from XCTestCase is found
class Case: XCTestCase {
    // test that a valid test case is found
    func testValid() {}
    // test that a valid throwing test case is found
    func testValidThrows() throws {
        XCTFail()
    }
    // test that a valid name, but invalid signature is ignored
    func testArgumentsShouldIgnore(_ arg: Int) {}
    // test that a valid name, but invalid return is ignored
    func testReturnShouldIgnore() -> Int { return 0 }

    // TODO: TEST: Remove existing allTests
    static let allTests = [
        ("testValid", testValid),
        ("testValid", testValidThrows),
    ]
}

class NotCase {
    // test that a valid signature and name in non XCTestCase is ignored
    func testShouldIgnore() {}
}

// test that a class inheriting from a class
// inheriting from XCTestCase is found
class Inherited: Case {
    func testAddition() {}
}

// test that a class inheriting from a class
// inheriting from a class, inheriting
// from XCTestCase is found
class DoubleInherited: Inherited {
    func testAnotherAddition() {}
}

extension Case {
    // test that a declaration in extension is found
    func testInExtension() {}
}

class NotTestClass {
    // test that a case in nested in non-case class is found
    class NestedCase: XCTestCase {
        func testValid() {}
    }
}

extension NotTestClass.NestedCase {
    // test that a valid declaration in extension of nested class is found
    func testNestedExtension() {}
}

class One {
    class Two {
        // test that multi-nested cases are found
        class Three: XCTestCase {
            func testValid() {}
        }
    }
}

extension One.Two.Three {
    // test that multi nested extension declarations are found
    func testAlsoValid() {}
}

extension NotTestClass {
    // test that a case nested in non-case class extension is found
    class NestedInExtensionCase: XCTestCase {
        func testValid() throws {}
    }
}

struct NotTestStruct {
    // test that a case in nested in non-case struct is found
    class NestedCase: XCTestCase {
        func testValid() {}
    }
}

extension NotTestStruct {
    // test that a case nested in non-case struct extension is found
    class NestedInExtensionCase: XCTestCase {
        func testValid() {}
    }
}

// test that a valid name, but global declaration is ignored
func testGlobalShouldIgnore() {}
