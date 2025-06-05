import Foundation
import Mustache

/// A struct that renders the template Mustache files.
struct TemplateRenderer {
    /// The template manifest.
    let manifest: TemplateManifest

    /// A flag that indicates whether the renderer should print verbose output.
    let verbose: Bool

    /// A flag that indicates whether the renderer should automatically answer "no" to all questions.
    let noQuestions: Bool

    /// Renders a project using the ``TemplateRendered/manifest``.
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

        if self.verbose { print("name: \(name.colored(.cyan))") }

        // Ask for variables not provided as arguments
        for variable in self.manifest.variables {
            try ask(variable: variable, to: &context)
        }

        print("Generating project files".colored(.cyan))
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
                print("\(variable.name): " + (confirm ? "Yes" : "No").colored(.cyan))
                return
            }
            let input = askBool(variable.description + " (--\(optionName)/--no-\(optionName))".colored(.cyan))
            context[variable.name] = input
            print("\(variable.name): " + (input ? "Yes" : "No").colored(.cyan))
        case .string:
            if context.keys.contains(variable.name) {
                let input = context[variable.name] as? String ?? ""
                print("\(variable.name): " + input.colored(.cyan))
                return
            }
            print(variable.description + " (--\(optionName))".colored(.cyan))
            print("> ".colored(.cyan), terminator: "")
            let input = readLine() ?? ""
            context[variable.name] = input
            print("\(variable.name): " + input.colored(.cyan))
        case .options(let options):
            if context.keys.contains(variable.name) {
                guard
                    let option = options.first(where: { option in
                        context[variable.name] as? [String: String] == option.data
                    })
                else {
                    return
                }
                print("\(variable.name): " + option.name.colored(.cyan))
                return
            }
            print(variable.description + " (--\(optionName))".colored(.cyan))
            for (index, option) in options.enumerated() {
                print("\(index + 1): ".colored(.cyan) + option.name)
            }
            var choice = 0
            while choice <= 0 || choice > options.count {
                print("> ".colored(.cyan), terminator: "")
                if let input = readLine(),
                    let inputChoice = Int(input),
                    inputChoice > 0 && inputChoice <= options.count
                {
                    choice = inputChoice
                }
            }
            context[variable.name] = options[choice - 1].data
            print("\(variable.name): " + options[choice - 1].name.colored(.cyan))
        case .variables(let nestedVars):
            if !context.keys.contains(variable.name) {
                let confirm = askBool(variable.description + " (--\(optionName)/--no-\(optionName))".colored(.cyan))
                print("\(variable.name): " + (confirm ? "Yes" : "No").colored(.cyan))
                guard confirm else { return }
            } else {
                if let confirm = context[variable.name] as? Bool {
                    print("\(variable.name): " + (confirm ? "Yes" : "No").colored(.cyan))
                    guard confirm else { return }
                } else if context[variable.name] != nil {
                    print("\(variable.name): " + "Yes".colored(.cyan))
                }
            }

            var nestedContext: [String: Any] = context[variable.name] as? [String: Any] ?? [:]
            for nestedVar in nestedVars {
                try ask(variable: nestedVar, to: &nestedContext, prefix: optionName + ".")
            }
            context[variable.name] = nestedContext
        }

        /// Asks the user a boolean question.
        ///
        /// - Parameter question: The text to display to the user.
        ///
        /// - Returns: The user's answer.
        func askBool(_ question: String) -> Bool {
            print(question)
            if self.noQuestions {
                print("y/n> ".colored(.cyan) + "no".colored(.yellow))
                return false
            }
            print("y/n> ".colored(.cyan), terminator: "")
            var input = readLine()?.lowercased() ?? ""
            while !input.starts(with: "y") && !input.starts(with: "n") {
                print(question)
                print("[y]es or [n]o> ".colored(.cyan), terminator: "")
                input = readLine()?.lowercased() ?? ""
            }
            return input.starts(with: "y")
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
            if self.verbose { print("+ " + file.name) }
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
