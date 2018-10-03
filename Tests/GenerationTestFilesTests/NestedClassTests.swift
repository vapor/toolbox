import XCTest

class A {
    func testLooksValidIgnore0() {}
    class B: XCTestCase {}
}

extension A {
    class C: XCTestCase {}
}

extension A.B {
    func testIsValid() throws {}
    class C: XCTestCase {}
}

extension A {
    func testLooksValidIgnore1() {}
}

class F: XCTestCase {}

enum D {
    class A: XCTestCase {}
    // test discovers that B inherits from D.A which is valid
    // if B is nested,
    // look for A that would also be nested
    // if available, use that to compare
    class B: A {}
    class C: XCTestCase {
        func testValid() {}
    }
    class D: F {}
}

extension D {
    func testLooksValidIgnore2() {}
}

protocol Bar {}
class E: Bar {}
