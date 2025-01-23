struct TemplateManifest: Decodable, Sendable {
    struct Variable: Decodable, Sendable {
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

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)

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

    struct File: Decodable, Sendable {
        enum Kind {
            case file(dynamic: Bool)
            case folder(files: [File])
        }

        enum Condition {
            case exists(variable: String)
        }

        var name: String
        var dynamicName: String?
        var condition: Condition?
        var type: Kind

        enum Keys: String, CodingKey {
            case file
            case folder
            case files
            case dynamic
            case condition
            case `if`
            case dynamic_name
        }

        init(from decoder: any Decoder) throws {
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
                self.dynamicName = try container.decodeIfPresent(String.self, forKey: .dynamic_name)
            }
        }
    }

    var name: String
    var variables: [Variable]
    var files: [File]
}
