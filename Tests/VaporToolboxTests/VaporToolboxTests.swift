import Testing
import Yams

@testable import VaporToolbox

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("Vapor Toolbox Tests")
struct VaporToolboxTests {
    #if !os(Android)
    @Test("Vapor.preprocess")
    func preprocess() async throws {
        #expect(Vapor.manifest == nil)
        try await Vapor.preprocess([])
        #expect(Vapor.manifest != nil)
    }
    #endif

    @Test("Vapor.version")
    func version() async {
        #expect(await Vapor.version.contains("toolbox: "))
    }

    #if !os(Android)
    @Test("Template Manifest", arguments: ["manifest.yml", "manifest.json"])
    func templateManifest(_ file: String) throws {
        let manifestPath = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Manifests").appending(path: file)
        let manifestData = try Data(contentsOf: manifestPath)
        let manifest =
            if manifestPath.pathExtension == "json" {
                try JSONDecoder().decode(TemplateManifest.self, from: manifestData)
            } else {
                try YAMLDecoder().decode(TemplateManifest.self, from: manifestData)
            }

        #expect(manifest.name == "Testing Vapor Template")
        #expect(manifest.variables.count == 6)
        #expect(manifest.variables[1].type == .bool)
        #expect(manifest.files.count == 10)

        guard let deployOptions = manifest.variables.first(where: { $0.name == "deploy" })?.type,
            case .options(let options) = deployOptions
        else {
            Issue.record("Deploy options not found in manifest")
            return
        }

        for option in options {
            if option.name == "DigitalOcean" {
                #expect(option.description == nil)
            } else {
                #expect(option.description != nil)
            }
        }
    }
    #endif

    @Test("Kebab Cased", arguments: ["Hello, World!", "hello-world", "21_hello-World", "hello1world"])
    func kebabcased(_ string: String) {
        #expect(string.kebabcased == "hello-world")
    }

    @Test("Pascal Cased", arguments: ["Hello, World!", "hello-world", "21_hello-World", "hello1world"])
    func pascalcased(_ string: String) {
        #expect(string.pascalcased == "HelloWorld")
    }

    @Test("Valid Name", arguments: ["hello_world", "helloWorld", "HelloWorld", "helloWorld123", "__helloWorld_123", "_123"])
    func isValidName(_ string: String) {
        #expect(string.isValidName)
    }

    @Test("Invalid Name", arguments: ["hello world", "hello-world", "hello@world", "hello.world", "hello, world", "21helloWorld", ""])
    func isInvalidName(_ string: String) {
        #expect(!string.isValidName)
    }
}
