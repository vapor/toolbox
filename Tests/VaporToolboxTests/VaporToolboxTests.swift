import ArgumentParser
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
    @Test("Vapor.version")
    func version() async {
        #expect(await Vapor.version.contains("toolbox: "))
    }

    /// These tests modify the global `Vapor.manifest` variable,
    /// so they must be serialized to avoid race conditions.
    @Suite("Vapor.manifest Tests", .serialized)
    struct VaporManifestTests {
        #if !os(Android)
        @Test("Vapor.preprocess")
        func preprocess() async throws {
            defer { Vapor.manifest = nil }

            #expect(Vapor.manifest == nil)
            try await Vapor.preprocess([])
            #expect(Vapor.manifest != nil)
        }
        #endif

        @Test("New command parses nested flag and nested options", arguments: [["--fluent"], []])
        func parseNestedOptions(flags: [String]) throws {
            defer { Vapor.manifest = nil }

            let manifestJSON = #"""
                {
                    "name": "Testing Vapor Template",
                    "variables": [
                        {
                            "name": "fluent",
                            "description": "Would you like to use Fluent (ORM)?",
                            "type": "nested",
                            "variables": [
                                {
                                    "name": "db",
                                    "description": "Which database would you like to use?",
                                    "type": "option",
                                    "options": [
                                        { "name": "Postgres", "data": { "id": "psql" } },
                                        { "name": "MySQL", "data": { "id": "mysql" } },
                                        { "name": "SQLite", "data": { "id": "sqlite" } }
                                    ]
                                }
                            ]
                        },
                        {
                            "name": "leaf",
                            "description": "Would you like to use Leaf (templating)?",
                            "type": "bool"
                        }
                    ],
                    "files": []
                }
                """#
            Vapor.manifest = try JSONDecoder().decode(TemplateManifest.self, from: Data(manifestJSON.utf8))

            let command = try #require(
                Vapor.New.parseAsRoot(["PersonalSite", "--fluent.db", "MySQL", "--leaf"] + flags) as? Vapor.New
            )

            let fluent = command.variables["fluent"] as? [String: Any]
            let fluentDB = fluent?["db"] as? [String: String]

            #expect(fluentDB?["id"] == "mysql")
            #expect(command.variables["leaf"] as? Bool == true)
        }
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
