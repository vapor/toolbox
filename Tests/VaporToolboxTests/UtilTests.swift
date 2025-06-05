import Testing

@testable import VaporToolbox

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

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
