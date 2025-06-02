#if canImport(Testing)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import Testing

@testable import VaporToolbox

@Suite("Util Tests")
struct UtilTests {
    @Test("escapeshellarg")
    func escapeshellarg() {
        var string: String
        var escapedString: String { VaporToolbox.escapeshellarg(string) }

        string = "Hello, World!"
        #expect(escapedString == "'Hello, World!'")

        string = "Hello, 'World'!"
        #expect(escapedString == "'Hello, '\\''World'\\''!'")
    }
}
#endif  // canImport(Testing)
