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
        if let condition = file.condition {
            switch condition {
            case .exists(let variable):
                guard context.keys.contains(variable) else {
                    return
                }
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
    fileprivate var kebabcased: String {
        .init(
            self
                .flatMap { $0.isWhitespace ? "-" : "\($0)" }
                .enumerated()
                .flatMap { $0 > 0 && $1.isUppercase ? "-\($1.lowercased())" : "\($1.lowercased())" }
        )
    }
}
