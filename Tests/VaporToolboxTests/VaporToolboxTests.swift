#if canImport(Testing)
import Foundation
import Testing
import Yams

@testable import VaporToolbox

@Suite("VaporToolbox Tests")
struct VaporToolboxTests {
    @Test("Vapor.preprocess")
    func preprocess() async throws {
        #expect(Vapor.manifest == nil)
        try await Vapor.preprocess([])
        #expect(Vapor.manifest != nil)
    }

    @Test("Vapor.version")
    func version() {
        #expect(Vapor.version.contains("toolbox: "))
    }

    @Test("Template Manifest", arguments: ["manifest.yml", "manifest.json"])
    func templateManifest(_ file: String) throws {
        let manifestPath = URL(filePath: #filePath).deletingLastPathComponent().appending(path: file)
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
            Issue.record()
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

    @Test("Kebab Cased", arguments: ["Hello, World!", "hello-world", "21_hello-World", "hello1world"])
    func kebabcased(_ string: String) {
        #expect(string.kebabcased == "hello-world")
    }

    @Test("Pascal Cased", arguments: ["Hello, World!", "hello-world", "21_hello-World", "hello1world"])
    func pascalcased(_ string: String) {
        #expect(string.pascalcased == "HelloWorld")
    }

    @Test("Is Valid Name")
    func isValidName() {
        let validNames = ["hello_world", "helloWorld", "HelloWorld", "helloWorld123", "__helloWorld_123", "_123"]
        for name in validNames {
            #expect(name.isValidName)
        }

        let invalidNames = ["hello world", "hello-world", "hello@world", "hello.world", "hello, world", "21helloWorld", ""]
        for name in invalidNames {
            #expect(!name.isValidName)
        }
    }
}
#endif  // canImport(Testing)
