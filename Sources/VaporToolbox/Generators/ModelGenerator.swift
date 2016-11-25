import Foundation
import Console

public final class ModelGenerator: AbstractGenerator {

    override public var id: String {
        return "model"
    }

    override public var signature: [Argument] {
        return super.signature + [
            Value(name: "properties", help: ["An optional list of properties in the format variable:type (e.g. firstName:string lastname:string)"]),
        ]
    }

    override public func generate(arguments: [String]) throws {
        guard let name = arguments.first else {
            throw ConsoleError.argumentNotFound
        }

        let filePath = "Sources/App/Models/\(name.capitalized).swift"
        let templatePath = defaultTemplatesDirectory + "ModelTemplate.swift"
        let fallbackURL = URL(string: defaultTemplatesURLString)!
        let ivars = arguments.values.filter { return $0.contains(":") }
        console.print("Model ivars => \(ivars)")
        try copyTemplate(atPath: templatePath, fallbackURL: fallbackURL, toPath: filePath) { (contents) in
            func spacing(_ x: Int) -> String {
                guard x > 0 else { return "" }
                var result = ""
                for _ in 0 ..< x {
                    result += " "
                }
                return result
            }

            var newContents = contents
            newContents = newContents.replacingOccurrences(of: "_CLASS_NAME_", with: name.capitalized)
            newContents = newContents.replacingOccurrences(of: "_IVAR_NAME_", with: name.lowercased())
            newContents = newContents.replacingOccurrences(of: "_TABLE_NAME_", with: name.pluralized)

            var ivarDefinitions = ""
            var ivarInitializers = ""
            var ivarDictionaryPairs = ""
            var tableRowsDefinition = ""
            for ivar in ivars {
                let components = ivar.components(separatedBy: ":")
                let ivarName = components.first!
                let ivarType = components.last!
                ivarDefinitions += "\(spacing(4))var \(ivarName): \(ivarType.capitalized)\n"
                ivarInitializers += "\(spacing(8))\(ivarName) = try node.extract(\"\(ivarName)\")\n"
                ivarDictionaryPairs += "\(spacing(12))\"\(ivarName)\": \(ivarName),\n"
                tableRowsDefinition += "\(spacing(12))\(name.lowercased()).\(ivarType.lowercased())(\"\(ivarName)\")\n"
            }
            ivarDefinitions = ivarDefinitions.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            ivarInitializers = ivarInitializers.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            ivarDictionaryPairs = ivarDictionaryPairs.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            tableRowsDefinition = tableRowsDefinition.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            newContents = newContents.replacingOccurrences(of: "_IVARS_DEFINITION_", with: ivarDefinitions)
            newContents = newContents.replacingOccurrences(of: "_IVARS_INITIALIZER_", with: ivarInitializers)
            newContents = newContents.replacingOccurrences(of: "_IVARS_DICTIONARY_PAIRS_", with: ivarDictionaryPairs)
            newContents = newContents.replacingOccurrences(of: "_TABLE_ROWS_DEFINITION_", with: tableRowsDefinition)

            return newContents
        }
        // TODO: generate test class
    }

}
