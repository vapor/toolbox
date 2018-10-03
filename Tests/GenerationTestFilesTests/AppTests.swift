import App
import XCTest

class SimpleTests: XCTestCase {
    func testValid() {}
}

class AlsoSimple: XCTestCase {
    func testValid() {}
}

class OtherFile: XCTestCase {}

//
//protocol Foo {}
//
//class Bar {
//    class Foo: XCTestCase {
//        func testMe() {
//
//        }
//    }
//}
//
//struct Barr {
//    class Boo: XCTestCase {
//        func testIt() {
//
//        }
//    }
//}
//
//extension Barr {
//    class Far: XCTestCase {
//        func testMe() {
//
//        }
//    }
//}
//
//struct Yup {
//    class Boo: XCTestCase {
//        func testFaaa() {
//
//        }
//    }
//}
//
//final class AppTests: XCTestCase, Foo {
//    func testNothing() throws {
//        // add your tests here
//        XCTAssert(true)
//    }
//
////    func testB() {
////
////    }
////
////    func TestC() {
////
////    }
////
////    func alt(_ arg: Int) {
////
////    }
////
////    func genericy<T>(foo: T) {
////
////    }
//
//    static let allTests = [
//        ("testNothing", testNothing)
//    ]
//}
//
//extension AppTests {
//    override var description: String {
//        return "lol, wat"
//    }
//}
//
//extension AppTests {
//    func testInExtension() {
//
//    }
//}
//
//func testOutsideDONT_INCLUDE() {
//
//}
//
