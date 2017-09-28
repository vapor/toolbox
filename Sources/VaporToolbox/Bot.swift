import Console
import Foundation
import JSON
import SourceKit
import Leaf

public final class Bot: Command {
    public let id = "bot"

    public let help: [String] = [
        "Generates boilerplate code."
    ]

    public let signature: [Console.Argument] = []

    public let console: ConsoleProtocol
    let file: FileManager
    let stem: Stem

    public init(_ console: ConsoleProtocol) {
        self.file = FileManager()
        self.console = console

        let file = DataFile(workDir: "/Users/tanner/dev/vapor/toolbox/Templates/")
        self.stem = Stem(file)
    }

    public func run(arguments: [String]) throws {
        guard projectInfo.isVaporProject() else {
            throw ToolboxError.general("Please run from the root directory of your Vapor project.")
        }

        console.info("Running Bot...")


        let modules = try file.contentsOfDirectory(atPath: "./Sources")
        for module in modules {
            let contents = try file.contentsOfDirectory(atPath: "./Sources/\(module)")
            if contents.contains("main.swift") {
                continue
            }

            var codeChunks: [Bytes] = []

            try handle(contents: contents, prefix: "./Sources/\(module)", codeChunks: &codeChunks)


            let serialized = codeChunks.joined(separator: [.newLine, .newLine, .newLine]).array

            file.createFile(atPath: "./Sources/\(module)/Generated.swift", contents: Data(bytes: serialized))
        }
    }

    func handle(contents: [String], prefix: String, codeChunks: inout [Bytes]) throws {
        for content in contents {
            var isDirectory: ObjCBool = false
            let path = prefix + "/" + content
            let exists = file.fileExists(atPath: path, isDirectory: &isDirectory)
            if exists && isDirectory.boolValue {
                let dir = prefix + "/" + content
                let sub = try file.contentsOfDirectory(atPath: dir)
                try handle(contents: sub, prefix: dir, codeChunks: &codeChunks)
            } else if exists {
                try handleFile(atPath: path, codeChunks: &codeChunks)
            }
        }
    }

    func handleFile(atPath path: String, codeChunks: inout [Bytes]) throws {
        guard path.hasSuffix(".swift") else {
            return
        }

        console.info("Parsing \(path)")
        let file = try Library.shared.parseFile(at: path)
        for c in file.classes {
            if c.inheritedTypes.contains("Model") {
                try handleModel(c, codeChunks: &codeChunks)
            }
        }
    }

    func handleModel(_ model: Entity, codeChunks: inout [Bytes]) throws {
        console.info("Found Model \(model.name)")

        try addRowConvertible(model, codeChunks: &codeChunks)
        try addPreparation(model, codeChunks: &codeChunks)
        try addJSONConvertible(model, codeChunks: &codeChunks)
    }

    func addRowConvertible(_ model: Entity, codeChunks: inout [Bytes]) throws {
        let props: [Property] = model.properties.map { prop in
            return Property(
                name: prop.name
            )
        }

        let template = try stem.spawnLeaf(at: "row-convertible.leaf")
        let array = try Node.array(props.map({ prop in
            var node = Node([:])
            try node.set("name", prop.name)
            return node
        }))

        var node = Node([:])
        try node.set("properties", array)
        try node.set("type", model.name)

        let context = LeafContext(node)
        let file = try stem.render(template, with: context)
        codeChunks.append(file)
    }

    func addPreparation(_ model: Entity, codeChunks: inout [Bytes]) throws {
        let preps: [Preparation] = model.properties.map { prop in

            let type: String
            let custom: String?
            if let override = prop.comment?.attributes["preparation-type"] {
                type = "custom"
                custom = override
            } else {
                type = prop.typeName.lowercased()
                custom = nil
            }

            return Preparation(
                type: type,
                name: prop.name,
                custom: custom
            )
        }

        let template = try stem.spawnLeaf(at: "preparation.leaf")
        let array = try Node.array(preps.map({ prep in
            var node = Node([:])
            try node.set("type", prep.type)
            try node.set("name", prep.name)
            try node.set("custom", prep.custom)
            return node
        }))

        var node = Node([:])
        try node.set("preparations", array)
        try node.set("type", model.name)

        let context = LeafContext(node)
        let file = try stem.render(template, with: context)
        codeChunks.append(file)
    }

    func addJSONConvertible(_ model: Entity, codeChunks: inout [Bytes]) throws {
        let props: [Property] = model.properties.flatMap { prop in
            if prop.comment?.attributes["json"] == "false" {
                return nil
            }
            return Property(
                name: prop.name
            )
        }

        let template = try stem.spawnLeaf(at: "json-convertible.leaf")
        let array = try Node.array(props.map({ prop in
            var node = Node([:])
            try node.set("name", prop.name)
            return node
        }))

        var node = Node([:])
        try node.set("properties", array)
        try node.set("type", model.name)

        let context = LeafContext(node)
        let file = try stem.render(template, with: context)
        codeChunks.append(file)
    }
}

struct Property {
    var name: String
}

struct Preparation {
    var type: String
    var name: String
    var custom: String?

    init(type: String, name: String, custom: String?) {
        self.type = type
        self.name = name
        self.custom = custom
    }
}
