import ArgumentParser
import Foundation
import Yams

extension Vapor {
    struct New: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Generates a new app.")

        @Argument(help: "Name of project and folder.")
        var name: String

        // Dynamic variables
        var variables: [String: Any] = [:]

        struct BuildOptions: ParsableArguments {
            @Option(
                name: [.customShort("T"), .long],
                help: ArgumentHelp(
                    "The URL of a Git repository to use as a template.",
                    valueName: "url"
                )
            )
            var template: String?

            @Option(help: "Template repository branch to use.")
            var branch: String?

            @Option(
                name: .shortAndLong,
                help: ArgumentHelp(
                    "The directory to place the new project in.",
                    valueName: "path"
                )
            )
            var output: String?

            @Flag(help: "Skips adding a first commit to the newly created repo.")
            var noCommit: Bool = false

            @Flag(help: "Skips adding a Git repository to the project folder.")
            var noGit: Bool = false

            @Flag(name: .shortAndLong, help: "Prints additional information.")
            var verbose: Bool = false
        }

        @OptionGroup(title: "Build Options")
        var buildOptions: BuildOptions

        mutating func run() throws {
            let cwd = URL(filePath: FileManager.default.currentDirectoryPath, directoryHint: .isDirectory)
            let projectURL =
                if let output = buildOptions.output {
                    URL(filePath: output, directoryHint: .isDirectory)
                } else {
                    cwd.appending(path: name, directoryHint: .isDirectory)
                }

            if let manifest = Vapor.manifest {
                defer { try? FileManager.default.removeItem(at: Vapor.templateURL) }

                try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: false)

                let renderer = TemplateRenderer(manifest: manifest, verbose: buildOptions.verbose)
                try renderer.render(
                    project: name,
                    from: Vapor.templateURL,
                    to: projectURL,
                    with: variables
                )
            } else {
                // If the template doesn't have a manifest (AKA doesn't need templating), just move the files
                try FileManager.default.moveItem(at: Vapor.templateURL, to: projectURL)
            }

            if !buildOptions.noGit {
                let gitDir = projectURL.appending(path: ".git").path()

                print("Creating git repository".colored(.cyan))
                if FileManager.default.fileExists(atPath: gitDir) {
                    try FileManager.default.removeItem(atPath: gitDir)  // Clear existing git history
                }
                try Process.runUntilExit(Vapor.gitURL, arguments: ["--git-dir=\(gitDir)", "init"])

                if !buildOptions.noCommit {
                    print("Adding first commit".colored(.cyan))
                    let gitDirFlag = "--git-dir=\(gitDir)"
                    let workTreeFlag = "--work-tree=\(projectURL.path())"
                    try Process.runUntilExit(Vapor.gitURL, arguments: [gitDirFlag, workTreeFlag, "add", "."])
                    try Process.runUntilExit(
                        Vapor.gitURL, arguments: [gitDirFlag, workTreeFlag, "commit", "-m", "Generate Vapor project."])
                }
            }

            // Figure out the shortest relative path to the new project
            let cwdPath = cwd.path()
            var cdInstruction = projectURL.path()
            if projectURL.deletingLastPathComponent().path().commonPrefix(with: cwdPath) == cwdPath {
                cdInstruction = projectURL.lastPathComponent  // Is in current directory
            }

            if buildOptions.verbose { printDroplet() }
            print("Project \(name.colored(.cyan)) has been created!")
            if buildOptions.verbose { print() }
            print("Use " + "cd \(Process.shell.escapeshellarg(cdInstruction))".colored(.cyan) + " to enter the project directory")
            print(
                "Then open your project, for example if using Xcode type "
                    + "open Package.swift".colored(.cyan)
                    + " or "
                    + "code .".colored(.cyan)
                    + " if using VSCode"
            )
        }
    }
}

extension Vapor.New: CustomReflectable {
    var customMirror: Mirror {
        func createChild(for variable: TemplateManifest.Variable, prefix: String = "") -> Mirror.Child {
            let name = prefix.isEmpty ? variable.name : "\(prefix)\(variable.name)"

            switch variable.type {
            case .bool:
                return Mirror.Child(label: name, value: Flag(inversion: .prefixedNo, help: ArgumentHelp(variable.description)))
            case .string:
                return Mirror.Child(label: name, value: Option<String>(help: ArgumentHelp(variable.description, valueName: variable.name)))
            case .options(let options):
                return Mirror.Child(
                    label: name,
                    value: Option<String>(
                        help: ArgumentHelp(
                            variable.description + " (values: " + options.map(\.name).joined(separator: ", ") + ")",
                            valueName: variable.name
                        )
                    )
                )
            case .variables(_):
                // Add the flag for the base variable
                return Mirror.Child(label: name, value: Flag(inversion: .prefixedNo, help: ArgumentHelp(variable.description)))
            }
        }

        func processNestedVariables(_ variable: TemplateManifest.Variable, prefix: String = "") -> [Mirror.Child] {
            var children = [createChild(for: variable, prefix: prefix)]

            if case .variables(let nestedVars) = variable.type {
                children += nestedVars.flatMap {
                    processNestedVariables($0, prefix: prefix.isEmpty ? "\(variable.name)." : "\(prefix)\(variable.name).")
                }
            }

            return children
        }

        let baseChildren = [
            Mirror.Child(label: "name", value: _name),
            Mirror.Child(label: "buildOptions", value: _buildOptions),
        ]

        let variableChildren = Vapor.manifest?.variables.flatMap { processNestedVariables($0) } ?? []

        return Mirror(Vapor.New(), children: baseChildren + variableChildren)
    }

    enum CodingKeys: CodingKey {
        case name
        case buildOptions

        case dynamic(String)

        init?(stringValue: String) {
            switch stringValue {
            case "name": self = .name
            case "buildOptions": self = .buildOptions
            default:
                let components = stringValue.split(separator: ".")
                guard let firstComponent = components.first else { return nil }
                let baseKey = String(firstComponent)

                guard let variables = Vapor.manifest?.variables else {
                    return nil
                }

                let baseExists = variables.contains { variable in
                    if variable.name == baseKey {
                        // If the base key has nested variables, register both
                        if case .variables(_) = variable.type { return true }
                        // Otherwise, register only if it's a single key
                        return components.count == 1
                    }
                    return false
                }
                guard baseExists else { return nil }

                // Register both the base key and the full path
                self =
                    if components.count == 1 {
                        .dynamic(baseKey)
                    } else {
                        .dynamic(stringValue)
                    }
            }
        }

        var stringValue: String {
            switch self {
            case .name: return "name"
            case .buildOptions: return "buildOptions"
            case .dynamic(let string): return string
            }
        }

        // Not used
        var intValue: Int? { nil }
        init?(intValue _: Int) { nil }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(Argument.self, forKey: .name).wrappedValue
        buildOptions = try container.decode(OptionGroup<BuildOptions>.self, forKey: .buildOptions).wrappedValue

        guard let lockVariables = Vapor.manifest?.variables else { return }

        func decodeVariable(_ variable: TemplateManifest.Variable, path: String) throws -> Any? {
            switch variable.type {
            case .bool:
                return try container.decode(Flag.self, forKey: .dynamic(path)).wrappedValue
            case .string:
                return try container.decode(Option<String>.self, forKey: .dynamic(path)).wrappedValue
            case .options(let options):
                let optionName = try container.decode(Option<String>.self, forKey: .dynamic(path)).wrappedValue
                guard let option = options.first(where: { $0.name.lowercased().hasPrefix(optionName.lowercased()) }) else {
                    throw DecodingError.dataCorruptedError(forKey: .dynamic(path), in: container, debugDescription: "The value is invalid.")
                }
                return option.data
            case .variables(let nestedVars):
                let flag = (try? container.decode(Flag<Bool>.self, forKey: .dynamic(path)).wrappedValue) ?? false
                if !flag {
                    return nil
                }

                var nested: [String: Any] = [:]
                for nestedVar in nestedVars {
                    if let value = try decodeVariable(nestedVar, path: "\(path).\(nestedVar.name)") {
                        nested[nestedVar.name] = value
                    }
                }
                return nested.isEmpty ? nil : nested
            }
        }

        // Decode top-level variables
        for variable in lockVariables {
            if let value = try decodeVariable(variable, path: variable.name) {
                variables[variable.name] = value
            }
        }
    }
}
