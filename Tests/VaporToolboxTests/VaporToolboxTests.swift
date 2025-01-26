import Foundation
import Testing
import Yams

@testable import VaporToolbox

@Suite("VaporToolbox Tests")
struct VaporToolboxTests {
    @Test("Vapor.preprocess")
    func preprocess() throws {
        #expect(Vapor.manifest == nil)
        try Vapor.preprocess([])
        #expect(Vapor.manifest != nil)
    }

    @Test("Template Manifest")
    func templateManifest() throws {
        let manifestPath = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "manifest.yml")
        let manifestData = try Data(contentsOf: manifestPath)
        let manifest = try YAMLDecoder().decode(TemplateManifest.self, from: manifestData)

        #expect(manifest.name == "Testing Vapor Template")
        #expect(manifest.variables.count == 6)
        #expect(manifest.files.count == 10)
    }

    @Test("Kebab Cased")
    func kebabcased() {
        let string = "Hello, World!"
        #expect(string.kebabcased == "hello-world")
    }
}
