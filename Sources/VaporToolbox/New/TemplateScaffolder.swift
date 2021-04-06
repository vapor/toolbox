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

    func scaffold(name: String, from source: String, to destination: String, using input: inout CommandInput) throws {
        assert(source.hasPrefix("/"))
        assert(destination.hasPrefix("/"))
        var context: [String: MustacheData] = [:]
        context["name"] = .string(name)
        context["name_kebab"] = .string(name.kebabcased())
        self.console.output(key: "name", value: name)
        for variable in self.manifest.variables {
            try self.ask(variable: variable, to: &context, using: &input)
        }
        self.console.info("Generating project files")
        for file in self.manifest.files {
            try self.scaffold(file: file, from: source.trailingSlash, to: destination.trailingSlash, context: context)
        }
    }

    private func ask(
        variable: TemplateManifest.Variable,
        to context: inout [String: MustacheData],
        using input: inout CommandInput,
        prefix: String = ""
    ) throws {
        let optionName = prefix + variable.name
        switch variable.type {
        case .string:
            let value = self.console.ask("\(variable.description) \("(--\(optionName))", style: .info)")
            context[variable.name] = .string(value)
            self.console.output(key: variable.name, value: value)
        case .bool:
            let confirm: Bool
            if let index = input.arguments.firstIndex(where: { $0 == "--\(optionName)" }) {
                input.arguments.remove(at: index)
                confirm = true
            } else if let index = input.arguments.firstIndex(where: { $0 == "--no-\(optionName)" }) {
                input.arguments.remove(at: index)
                confirm = false
            } else {
                confirm = self.console.confirm("\(variable.description) \("(--\(optionName)/--no-\(optionName))", style: .info)")
            }

            if confirm {
                context[variable.name] = .string(true.description)
                self.console.output(key: variable.name, value: "Yes")
            } else {
                self.console.output(key: variable.name, value: "No")
            }
        case .options(let options):
            let option: TemplateManifest.Variable.Option
            if let index = input.arguments.firstIndex(where: { $0.hasPrefix("--\(optionName)") }) {
                let next = input.arguments.index(after: index)
                guard next < input.arguments.endIndex else {
                    throw "Option --\(optionName) requires a value"
                }
                let name = input.arguments[next]
                input.arguments.remove(at: next)
                input.arguments.remove(at: index)
                guard let found = options.filter({
                    $0.name.lowercased().hasPrefix(name.lowercased())
                }).first else {
                    throw "No --\(optionName) option matching '\(name)'"
                }
                option = found
            } else {
                option = self.console.choose("\(variable.description) \("(--\(optionName))", style: .info)", from: options, display: { option in
                    option.name.consoleText()
                })
            }
            self.console.output(key: variable.name, value: option.name)
            context[variable.name] = .dictionary(option.data.mapValues { .string($0) })
        case .variables(let variables):
            let confirm: Bool
            if input.arguments.contains(where: { $0.hasPrefix("--\(optionName)." )}) {
                confirm = true
            } else if let index = input.arguments.firstIndex(where: { $0.hasPrefix("--\(optionName)") }) {
                input.arguments.remove(at: index)
                confirm = true
            } else if let index = input.arguments.firstIndex(where: { $0 == "--no-\(optionName)" }) {
                input.arguments.remove(at: index)
                confirm = false
            } else {
                confirm = self.console.confirm("\(variable.description) \("(--\(optionName)/--no-\(optionName))", style: .info)")
            }
            if confirm {
                self.console.output(key: variable.name, value: "Yes")
                var nested: [String: MustacheData] = [:]
                for child in variables {
                    try self.ask(variable: child, to: &nested, using: &input, prefix: "\(prefix)\(variable.name).")
                }
                context[variable.name] = .dictionary(nested)
            } else {
                self.console.output(key: variable.name, value: "No")
            }
        }
    }

    private func scaffold(
        file: TemplateManifest.File,
        from source: String,
        to destination: String,
        context: [String: MustacheData]
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
            self.console.output("+ " + file.name.consoleText())
            if dynamic {
                let template = try String(contentsOf: source.appendingPathComponents(file.name).asFileURL, encoding: .utf8)
                try MustacheRenderer().render(template: template, data: context)
                    .write(to: URL(fileURLWithPath: destination.appendingPathComponents(file.name)), atomically: true, encoding: .utf8)
            } else {
                try FileManager.default.moveItem(
                    atPath: source.appendingPathComponents(file.name),
                    toPath: destination.appendingPathComponents(file.name))
            }
        case .folder(let files):
            let folder = file
            try FileManager.default.createDirectory(atPath: destination.appendingPathComponents(folder.name), withIntermediateDirectories: false)
            for file in files {
                try self.scaffold(
                    file: file,
                    from: source.appendingPathComponents(folder.name).trailingSlash,
                    to: destination.appendingPathComponents(folder.name).trailingSlash,
                    context: context
                )
            }
        }
    }
}

fileprivate extension StringProtocol {
    func kebabcased() -> String {
        return .init(self
            .flatMap { $0.isWhitespace ? "-" : "\($0)" }
            .enumerated().flatMap { $0 > 0 && $1.isUppercase ? "-\($1.lowercased())" : "\($1.lowercased())" }
        )
    }
}

extension Console {
    func output(key: String, value: String) {
        self.output(key.consoleText() + ": " + value.consoleText(.info))
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
