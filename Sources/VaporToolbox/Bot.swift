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

            try handle(contents: contents, prefix: "./Sources/\(module)")
        }
    }

    func handle(contents: [String], prefix: String) throws {
        for content in contents {
            var isDirectory: ObjCBool = false
            let path = prefix + "/" + content
            let exists = file.fileExists(atPath: path, isDirectory: &isDirectory)
            if exists && isDirectory.boolValue {
                let dir = prefix + "/" + content
                let sub = try file.contentsOfDirectory(atPath: dir)
                try handle(contents: sub, prefix: dir)
            } else if exists {
                try handleFile(atPath: path)
            }
        }
    }

    func handleFile(atPath path: String) throws {
        guard path.hasSuffix(".swift") else {
            return
        }

        console.info("Parsing \(path)")
        let file = try Library.shared.parseFile(at: path)
        for c in file.classes {
            if c.inheritedTypes.contains("Model") {
                try handleModel(c)
            }
        }
    }

    func handleModel(_ model: Entity) throws {
        console.info("Found Model \(model.name)")

        let preps: [Preparation] = model.properties.map { prop in
            return Preparation(
                type: prop.typeName.lowercased(),
                name: prop.name
            )
        }

        let template = try stem.spawnLeaf(at: "preparations.leaf")
        let array = try Node.array(preps.map({ prep in
            var node = Node([:])
            try node.set("type", prep.type)
            try node.set("name", prep.name)
            return node
        }))

        var node = Node([:])
        try node.set("preparations", array)
        try node.set("type", model.name)
        
        let context = LeafContext(node)
        let file = try stem.render(template, with: context)
        print(file.makeString())
    }
}

struct Preparation {
    var type: String
    var name: String

    init(type: String, name: String) {
        self.type = type
        self.name = name
    }
}
