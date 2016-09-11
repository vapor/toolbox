import XCTest
import Foundation
@testable import VaporToolbox


class VaporConfigTests: XCTestCase {

    func testRecursion() throws {
        let directory = #file.components(separatedBy: "/").dropLast().joined(separator: "/") + "/VaporConfigResources"
//        let enumerator = FileManager.default.enumerator(atPath: directory)
//        while let next = enumerator?.nextObject() {
//            print("\(next)")
//        }
        print(try FileManager.default.vaporConfigFiles(rootDirectory: directory))
    }
}
