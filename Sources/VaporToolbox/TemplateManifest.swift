/// The structure of the `manifest.yml` file.
struct TemplateManifest: Decodable, Sendable {
    var name: String
    var variables: [Variable]
    var files: [File]
}

extension TemplateManifest {
    /// A variable that the user has to provide and that will be used to render the template files.
    struct Variable: Decodable, Sendable, Equatable {
        var name: String
        var description: String
        var type: Kind

        enum Kind: Equatable {
            case string
            case bool

            /// The user has to choose between a list of options.
            case options([Option])

            /// This variable contains other nested variables.
            case variables([Variable])

            static func == (lhs: Kind, rhs: Kind) -> Bool {
                switch (lhs, rhs) {
                case (.string, .string), (.bool, .bool):
                    return true
                case (.options(let lhs), .options(let rhs)):
                    return lhs == rhs
                case (.variables(let lhs), .variables(let rhs)):
                    return lhs == rhs
                default:
                    return false
                }
            }
        }

        /// An option that the user can choose from.
        struct Option: Decodable, Equatable {
            var name: String
            var description: String

            /// The data associated with the option that will be stored in the context.
            var data: [String: String]
        }

        // MARK: - Decodable
        enum CodingKeys: String, CodingKey {
            case name
            case description
            case type
            case options
            case variables
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.name = try container.decode(String.self, forKey: .name)
            self.description = try container.decode(String.self, forKey: .description)
            self.type =
                switch try container.decode(String.self, forKey: .type) {
                case "string":
                    .string
                case "bool":
                    .bool
                case "option":
                    try .options(container.decode([Option].self, forKey: .options))
                case "nested":
                    try .variables(container.decode([Variable].self, forKey: .variables))
                default:
                    fatalError("Unknown variable type")
                }
        }
    }
}

extension TemplateManifest {
    /// A file or a folder to render.
    struct File: Decodable, Sendable {
        var name: String

        /// Contains a Mustache string that will be rendered and used as the file or folder name.
        var dynamicName: String?

        /// The ``TemplateManifest/Variable`` name that has to be provided for this file to be rendered.
        var condition: Condition?

        var type: Kind

        enum Kind {
            case file(dynamic: Bool)
            case folder(files: [File])
        }

        enum Condition {
            /// The file will be rendered only if the variable exists.
            case exists(variable: String)
        }

        // MARK: - Decodable
        enum CodingKeys: String, CodingKey {
            case file
            case folder
            case files
            case dynamic
            case condition
            case `if`
            case dynamicName = "dynamic_name"
        }

        init(from decoder: any Decoder) throws {
            do {
                self.name = try decoder.singleValueContainer().decode(String.self)
                self.type = .file(dynamic: false)
            } catch {
                let container = try decoder.container(keyedBy: CodingKeys.self)
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
                self.dynamicName = try container.decodeIfPresent(String.self, forKey: .dynamicName)
            }
        }
    }
}
