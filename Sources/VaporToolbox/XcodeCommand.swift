import Vapor
import Globals

// TODO: Xcode Additions
// automatically add xcconfig
// swift package generate-xcodeproj --xcconfig-overrides Sandbox.xcconfig
//
// automatically add environment variables to project file, more work,
// but would be nice
//
//
// Generates an Xcode project
struct XcodeCommand: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["generates xcode projects for spm packages."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> Future<Void> {
        let environmentVariablesByScheme: [String: XMLElement]
        do {
            let xcodeproj = try findFirstXcodeprojFile(with: URL(fileURLWithPath: ".", isDirectory: true))
            environmentVariablesByScheme = try getEnvironmentVariablesByScheme(with: xcodeproj)
        } catch {
            environmentVariablesByScheme = [:]
        }
        ctx.console.output("generating xcodeproj...")
        let generateProcess = Process.asyncExecute(
            "swift",
            ["package", "generate-xcodeproj"],
            on: ctx.container
        ) { output in
            switch output {
            case .stderr(let err):
                let str = String(bytes: err, encoding: .utf8) ?? "error"
                ctx.console.output("error:", style: .error, newLine: true)
                ctx.console.output(str, style: .error, newLine: false)
            case .stdout(let out):
                let str = String(bytes: out, encoding: .utf8) ?? ""
                ctx.console.output(str.consoleText(), newLine: false)
            }
        }

        return generateProcess.map { val in
            if val == 0 {
                ctx.console.output(
                    "success.",
                    style: .info,
                    newLine: true
                )
                do {
                    let xcodeproj = try self.findFirstXcodeprojFile(with: URL(fileURLWithPath: ".", isDirectory: true))
                    try self.updateEnvironmentVariablesForSchemes(environmentVariablesByScheme, with: xcodeproj)
                } catch { }
                try Shell.bash("open *.xcodeproj")
            } else {
                ctx.console.output(
                    "failed to generate xcodeproj.",
                    style: .error,
                    newLine: true
                )
            }
        }
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
