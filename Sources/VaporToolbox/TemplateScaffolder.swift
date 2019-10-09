import Globals
import NIO
import Foundation
import ConsoleKit
import Mustache

struct TemplateScaffolder {
    let console: Console
    let manifest: TemplateManifest
    
    init(console: Console, manifest: TemplateManifest) {
        self.console = console
        self.manifest = manifest
    }

    func scaffold(from source: String, to destination: String) throws {
        assert(source.hasPrefix("/"))
        assert(destination.hasPrefix("/"))
        var context: [String: Any] = [:]
        for variable in self.manifest.variables {
            try self.ask(variable: variable, to: &context)
        }
        print(context)
        for file in self.manifest.files {
            try self.scaffold(
                file: file,
                from: source.trailingSlash,
                to: destination.trailingSlash,
                context: context
            )
        }
    }

    private func ask(
        variable: TemplateManifest.Variable,
        to context: inout [String: Any]
    ) throws {
        switch variable.type {
        case .string:
            let value = self.console.ask(variable.description.consoleText())
            context[variable.name] = value
        case .bool:
            let value = self.console.confirm(variable.description.consoleText())
            context[variable.name] = value
        case .options(let options):
            let option = self.console.choose(variable.description.consoleText(), from: options, display: { option in
                return option.name.consoleText(.info) + "\n" + option.description.consoleText()
            })
            context[variable.name] = option.data
        case .variables(let variables):
            if self.console.confirm(variable.description.consoleText()) {
                var nested: [String: Any] = [:]
                for child in variables {
                    try self.ask(variable: child, to: &nested)
                }
                context[variable.name] = nested
            }
        }
    }

    private func scaffold(
        file: TemplateManifest.File,
        from source: String,
        to destination: String,
        context: [String: Any]
    ) throws {
        assert(source.hasSuffix("/"))
        assert(destination.hasSuffix("/"))

        if let condition = file.condition {
            switch condition {
            case .exists(let variable):
                guard context.keys.contains(variable) else {
                    return
                }
            }
        }
        
        switch file.type {
        case .file(let dynamic):
            if dynamic {
                try Mustache.Template(path: source + file.name).render(context)
                    .write(to: URL(fileURLWithPath: destination + file.name), atomically: true, encoding: .utf8)
            } else {
                try Shell.move(source + file.name, to: destination + file.name)
            }
        case .folder(let files):
            let folder = file
            try Shell.makeDirectory(destination + folder.name)
            for file in files {
                try self.scaffold(
                    file: file,
                    from: source + folder.name.trailingSlash,
                    to: destination + folder.name.trailingSlash,
                    context: context
                )
            }
        }
    }
}

struct TemplateManifest: Decodable {
    struct Variable: Decodable {
        enum Kind {
            case string
            case bool
            case options([Option])
            case variables([Variable])
        }
        struct Option: Decodable {
            var name: String
            var description: String
            var data: [String: String]
        }
        var name: String
        var description: String
        var type: Kind

        enum Keys: String, CodingKey {
            case name
            case description
            case type
            case options
            case variables
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.description = try container.decode(String.self, forKey: .description)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "string":
                self.type = .string
            case "bool":
                self.type = .bool
            case "option":
                self.type = try .options(container.decode([Option].self, forKey: .options))
            case "nested":
                self.type = try .variables(container.decode([Variable].self, forKey: .variables))
            default:
                fatalError("Unknown variable type: \(type)")
            }
        }
    }

    struct File: Decodable {
        enum Kind {
            case file(dynamic: Bool)
            case folder(files: [File])
        }
        enum Condition {
            case exists(variable: String)
        }
        var name: String
        var condition: Condition?
        var type: Kind

        enum Keys: String, CodingKey {
            case file
            case folder
            case files
            case dynamic
            case condition
            case `if`
        }

        init(from decoder: Decoder) throws {
            do {
                self.name = try decoder.singleValueContainer().decode(String.self)
                self.type = .file(dynamic: false)
            } catch {
                let container = try decoder.container(keyedBy: Keys.self)
                if container.contains(.file) {
                    self.name = try container.decode(String.self, forKey: .file)
                    self.type = try .file(dynamic: container.decodeIfPresent(Bool.self, forKey: .dynamic) ?? false)
                } else {
                    self.name = try container.decode(String.self, forKey: .folder)
                    self.type = try .folder(files: container.decodeIfPresent([File].self, forKey: .files) ?? [])
                }
                if let variable = try container.decodeIfPresent(String.self, forKey: .if) {
                    self.condition = .exists(variable: variable)
                }
            }
        }
    }

    var name: String
    var variables: [Variable]
    var files: [File]
}
