import Foundation
import Mustache

struct TemplateRenderer {
    let manifest: TemplateManifest
    let verbose: Bool

    func render(
        project name: String,
        from sourceURL: URL,
        to destinationURL: URL,
        dependencies: Toolbox.New.DependenciesOptions
    ) throws {
        var context: [String: Any] = [:]
        context["name"] = name
        context["name_kebab"] = name.kebabcased

        if verbose { print("name: \(name.colored(.cyan))") }

        if dependencies.leaf {
            context["leaf"] = "true"
        }

        if let fluentDB = dependencies.fluent {
            let (module, url, id, version, key, emoji) =
                switch fluentDB {
                case .postgres:
                    ("Postgres", "postgres", "psql", "2.10.0", "is_postgres", "🐘")
                case .mysql:
                    ("MySQL", "mysql", "mysql", "4.7.0", "is_mysql", "🐬")
                case .sqlite:
                    ("SQLite", "sqlite", "sqlite", "4.8.0", "is_sqlite", "🪶")
                case .mongo:
                    ("Mongo", "mongo", "mongo", "1.4.0", "is_mongo", "🌱")
                }

            context["fluent"] = [
                "db": [
                    "module": module,
                    "url": url,
                    "id": id,
                    "version": version,
                    key: "true",
                    "emoji": emoji,
                ]
            ]
        }

        print("Generating project files".colored(.cyan))

        for file in self.manifest.files {
            try self.render(file: file, from: sourceURL, to: destinationURL, context: context)
        }
    }

    private func render(
        file: TemplateManifest.File,
        from sourceURL: URL,
        to destinationURL: URL,
        context: [String: Any]
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
                    file: file,
                    from: sourceURL.appending(path: folder.name, directoryHint: .isDirectory),
                    to: destinationFileURL,
                    context: context
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
