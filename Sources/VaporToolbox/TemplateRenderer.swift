import ConsoleKit
import Mustache

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A struct that renders the template Mustache files.
struct TemplateRenderer {
    /// The template manifest.
    let manifest: TemplateManifest

    /// A flag that indicates whether the renderer should print verbose output.
    let verbose: Bool

    /// The console to use for I/O operations.
    let console: Terminal

    /// Renders a project using the ``TemplateRenderer/manifest``.
    ///
    /// - Parameters:
    ///   - name: The name of the project.
    ///   - sourceURL: The URL of the template source.
    ///   - destinationURL: The URL of the destination folder where the project will be generated.
    ///   - variables: The manifest variables already provided as arguments.
    func render(
        project name: String,
        from sourceURL: URL,
        to destinationURL: URL,
        with variables: [String: Any]
    ) throws {
        var context = variables
        context["name"] = name.isValidName ? name : name.pascalcased
        context["name_kebab"] = name.kebabcased

        if self.verbose { self.console.output(key: "name", value: name) }

        // Ask for variables not provided as arguments
        for variable in self.manifest.variables {
            try ask(variable: variable, to: &context)
        }

        self.console.info("Generating project files")
        for file in self.manifest.files {
            try self.render(file, from: sourceURL, to: destinationURL, with: context)
        }
    }

    /// Asks the user for a variable, if it is not already provided.
    ///
    /// - Parameters:
    ///   - variable: The variable to ask for.
    ///   - context: The context where the variable will be stored and that will be used to render the template.
    ///   - prefix: The prefix to add to the variable name. Used for nested variables.
    private func ask(
        variable: TemplateManifest.Variable,
        to context: inout [String: Any],
        prefix: String = ""
    ) throws {
        let optionName = prefix + variable.name

        switch variable.type {
        case .bool:
            if context.keys.contains(variable.name) {
                let confirm = context[variable.name] as? Bool ?? false
                self.console.output(key: variable.name, value: confirm ? "Yes" : "No")
                return
            }
            let input = self.console.confirm("\(variable.description) \("(--\(optionName)/--no-\(optionName))", style: .info)")
            context[variable.name] = input
            self.console.output(key: variable.name, value: input ? "Yes" : "No")
        case .string:
            if context.keys.contains(variable.name) {
                let input = context[variable.name] as? String ?? ""
                self.console.output(key: variable.name, value: input)
                return
            }
            let input = self.console.ask("\(variable.description) \("(--\(optionName))", style: .info)")
            context[variable.name] = input
            self.console.output(key: variable.name, value: input)
        case .options(let options):
            if context.keys.contains(variable.name) {
                guard
                    let option = options.first(where: { option in
                        context[variable.name] as? [String: String] == option.data
                    })
                else {
                    return
                }
                self.console.output(key: variable.name, value: option.name)
                return
            }
            let choice = self.console.choose(
                "\(variable.description) \("(--\(optionName))", style: .info)",
                from: options
            ) {
                $0.name.consoleText()
            }
            context[variable.name] = choice.data
            self.console.output(key: variable.name, value: choice.name)
        case .variables(let nestedVars):
            if !context.keys.contains(variable.name) {
                let confirm = self.console.confirm("\(variable.description) \("(--\(optionName)/--no-\(optionName))", style: .info)")
                self.console.output(key: variable.name, value: confirm ? "Yes" : "No")
                guard confirm else { return }
            } else {
                if let confirm = context[variable.name] as? Bool {
                    self.console.output(key: variable.name, value: confirm ? "Yes" : "No")
                    guard confirm else { return }
                } else if context[variable.name] != nil {
                    self.console.output(key: variable.name, value: "Yes")
                }
            }

            var nestedContext: [String: Any] = context[variable.name] as? [String: Any] ?? [:]
            for nestedVar in nestedVars {
                try ask(variable: nestedVar, to: &nestedContext, prefix: optionName + ".")
            }
            context[variable.name] = nestedContext
        }
    }

    /// Renders a Mustache file from the template using the provided context.
    ///
    /// - Parameters:
    ///   - file: The file to render.
    ///   - sourceURL: The URL of the template source.
    ///   - destinationURL: The URL of the destination folder where the project will be generated.
    ///   - context: The context to use to render the files.
    private func render(
        _ file: TemplateManifest.File,
        from sourceURL: URL,
        to destinationURL: URL,
        with context: [String: Any]
    ) throws {
        // If the file has a condition on whether it should be rendered or not
        // check for the condition in the context, including nested variables.
        if case .exists(let rawVariable) = file.condition {
            // Check if the condition starts with "!" to invert the condition
            var variable = rawVariable
            var invert = false
            if variable.hasPrefix("!") {
                invert = true
                variable.removeFirst()
            }

            let components = variable.split(separator: ".").map { String($0) }
            var subContext: Any = context

            for component in components {
                guard
                    let dict = subContext as? [String: Any],
                    let value = dict[component]
                else {
                    // If here, it means the variable doesn't exist in the context.
                    // If invert==true, continue to render the file, otherwise return.
                    if invert { break } else { return }
                }

                if let bool = value as? Bool {
                    // If the condition in the manifest doesn't start with "!", `invert` is false,
                    // so if the value is false, return and don't render the file.
                    if bool == invert {
                        return
                    }
                }

                subContext = value
            }
        }

        let destinationFileName =
            if let dynamicName = file.dynamicName {
                try MustacheTemplate(string: dynamicName).render(context)
            } else {
                file.name
            }
        let destinationFileURL = destinationURL.appending(path: destinationFileName)

        switch file.type {
        case .file(let dynamic):
            if dynamic {
                let template = try String(contentsOf: sourceURL.appending(path: file.name), encoding: .utf8)
                try MustacheTemplate(string: template).render(context)
                    .write(to: destinationFileURL, atomically: true, encoding: .utf8)
            } else {
                try FileManager.default.moveItem(at: sourceURL.appending(path: file.name), to: destinationFileURL)
            }
            if self.verbose { self.console.print("+ " + file.name) }
        case .folder(let files):
            let folder = file
            try FileManager.default.createDirectory(at: destinationFileURL, withIntermediateDirectories: false)
            for file in files {
                try self.render(
                    file,
                    from: sourceURL.appending(path: folder.name, directoryHint: .isDirectory),
                    to: destinationFileURL,
                    with: context
                )
            }
        }
    }
}

extension String {
    var kebabcased: String {
        self
            .split(whereSeparator: { !$0.isLetter })
            .map { $0.lowercased() }
            .joined(separator: "-")
    }

    var pascalcased: String {
        self
            .split(whereSeparator: { !$0.isLetter })
            .map { $0.capitalized }
            .joined()
    }

    /// A Boolean value indicating whether the string is a valid name for a Swift target, file or type.
    var isValidName: Bool {
        self.wholeMatch(
            of:
                #/
                (?:\p{L}|_)         # match Letter or underscore
                (?:\p{L}|\p{N}|_)*  # match zero or more Letters, Numbers, and/or underscores
                /#
        ) != nil
    }
}
