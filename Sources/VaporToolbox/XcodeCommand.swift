import ConsoleKit
import Foundation
import Globals

// Generates an Xcode project
struct XcodeCommand: Command {
    struct Signature: CommandSignature { }

    let help = "Opens a Vapor project in Xcode."
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        do {
            let xcodeproj = try findFirstXcodeprojFile(with: URL(fileURLWithPath: ".", isDirectory: true))
            let environmentVariablesByScheme = try getEnvironmentVariablesByScheme(with: xcodeproj)
            try updateEnvironmentVariablesForSchemes(environmentVariablesByScheme, with: xcodeproj)
        } catch { }
        try Shell.bash("open Package.swift")
    }
    
    func findFirstXcodeprojFile(with directory: URL) throws -> URL {
        let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
        guard let xcodeprojFileURL = files?.first(where: { return ($0 as? URL)?.pathExtension == "xcodeproj" }) as? URL else {
            throw "No xcodeproj found in \(directory)"
        }
        return xcodeprojFileURL
    }
    
    func getSchemeFileURLs(with xcodeprojFileURL: URL) throws -> [URL]  {
        let schemeDirectoryURL = xcodeprojFileURL.appendingPathComponent("xcshareddata").appendingPathComponent("xcschemes")
        guard let schemes = FileManager.default.enumerator(at: schemeDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants]) else {
            throw "No schemes found in \(schemeDirectoryURL)"
        }
        return schemes.compactMap({ (scheme) -> URL? in
            guard let schemeFileURL = scheme as? URL, schemeFileURL.pathExtension == "xcscheme" else {
                return nil
            }
            return schemeFileURL
        })
    }
    
    func getEnvironmentVariablesByScheme(with xcodeprojFileURL: URL) throws -> [String: XMLElement] {
        let pairs = try getSchemeFileURLs(with: xcodeprojFileURL).compactMap { (schemeFileURL) -> (String, XMLElement)? in
            guard
                let document = try? XMLDocument(contentsOf: schemeFileURL),
                let environmentVariables = document.rootElement()?.elements(forName: "LaunchAction").first?.elements(forName: "EnvironmentVariables").first?.copy() as? XMLElement else {
                    return nil
            }
            return (schemeFileURL.lastPathComponent, environmentVariables)
        }
        return Dictionary(uniqueKeysWithValues: pairs)
    }
    
    func updateEnvironmentVariablesForSchemes(_ environmentVariablesByScheme: [String: XMLElement], with xcodeprojFileURL: URL) throws {
        let schemeFileURLs = try getSchemeFileURLs(with: xcodeprojFileURL)
        for schemeFileURL in schemeFileURLs {
            guard
                let document = try? XMLDocument(contentsOf: schemeFileURL),
                let launchAction = document.rootElement()?.elements(forName: "LaunchAction").first,
                let environmentVariables = environmentVariablesByScheme[schemeFileURL.lastPathComponent]
                else {
                    continue
            }
            if let indexOfExistingEnvironmentVariables = launchAction.elements(forName: "EnvironmentVariables").first?.index {
                launchAction.removeChild(at: indexOfExistingEnvironmentVariables)
                launchAction.insertChild(environmentVariables, at: indexOfExistingEnvironmentVariables)
            } else {
                launchAction.addChild(environmentVariables)
            }
            let updatedDocumentData = document.xmlData(options: [.documentValidate, .documentTidyXML])
            try updatedDocumentData.write(to: schemeFileURL)
        }
    }
}
