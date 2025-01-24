import Foundation
import Mustache

struct TemplateRenderer {
    let manifest: TemplateManifest
    let verbose: Bool

    func render(
        project name: String,
        from sourceURL: URL,
        to destinationURL: URL,
        with variables: [String: Any]
    ) throws {
        var context = variables
        context["name"] = name
        context["name_kebab"] = name.kebabcased

        if verbose { print("name: \(name.colored(.cyan))") }

        print("Generating project files".colored(.cyan))
        for file in self.manifest.files {
            try self.render(file, from: sourceURL, to: destinationURL, with: context)
        }
    }

    private func render(
        _ file: TemplateManifest.File,
        from sourceURL: URL,
        to destinationURL: URL,
        with context: [String: Any]
    ) throws {
        if case .exists(let variable) = file.condition {
            let components = variable.split(separator: ".").map { String($0) }
            var subContext: Any = context

            for component in components {
                guard
                    let dict = subContext as? [String: Any],
                    let value = dict[component]
                else {
                    return
                }

                if let bool = value as? Bool, !bool {
                    return
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
            if verbose { print("+ " + file.name) }
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

extension StringProtocol {
    var kebabcased: String {
        self
            .components(separatedBy: .alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .joined(separator: "-")
    }
}
