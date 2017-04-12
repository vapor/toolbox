import Console
import Vapor
import Cloud
import HTTP

public final class ProviderAdd: Command {
    public let id = "add"
    
    public let signature: [Argument] = [
        Value(name: "provider")
    ]
    
    public let help: [String] = [
        "Adds a provider to the Vapor project"
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        try console.warnGitClean()
        guard !arguments.isEmpty else {
            throw CommandError.general("Expected to receive a provider as an argument")
        }

        var provider = arguments[1]
        guard projectInfo.isVaporProject() else {
            throw CommandError.general("Run this command in a Vapor project directory")
        }
        
        if provider.hasSuffix(".git") {
            provider = String(provider.characters.dropLast(4))
        }
        if !provider.hasSuffix("-provider") {
            provider += "-provider"
        }
        
        let repo: String
        if provider.contains("/") {
            repo = provider
        } else {
            repo = "vapor/\(provider)"
        }
        
        let package = try DataFile.load(path: "Package.swift").makeString()
        
        guard !package.contains(repo) else {
            throw CommandError.general("Package.swift already contains \(provider)")
        }
        
        // create loading bar
        let bar = console.loadingBar(
            title: "Loading tags",
            animated: !arguments.isVerbose
        )

        // fetch tags from github
        let res: Response
        do {
            res = try bar.perform {
                return  try EngineClient.get("https://api.github.com/repos/\(repo)/tags")
            }
        } catch {
            throw CommandError.general("GitHub API request failed")
        }
        
        guard res.status == .ok else {
            throw CommandError.general("Could not find \(repo)")
        }
        
        // parse github tags into class
        guard let tagsArray = res.json?.array else {
            throw CommandError.general("Invalid tags response from GitHub")
        }
        let tags = try tagsArray.map { tagJSON in
            return try Tag(json: tagJSON)
        }
        
        // sort tags by major and pre-release id
        var majorVersions: [String: Tag] = [:]
        for tag in tags.reversed() {
            majorVersions[tag.special] = tag
        }
        
        // create a list of ordered choices
        let choices: [Tag] = majorVersions
            .values
            .array
            .sorted(by: { $0.major > $1.major })
        
        // ask which tag
        let choice = try console.giveChoice(title: "Which version?", in: choices)
        console.print("Selected version ", newLine: false)
        console.info(choice.description)
        
        let url = "https://github.com/\(repo).git"
        
        let packageEntry: String
        if let pre = choice.prereleaseIdentifier {
            packageEntry = ".Package(url: \"\(url)\", Version(\(choice.major),\(choice.minor),\(choice.patch), prereleaseIdentifiers: [\"\(pre)\"]))"
        } else {
            packageEntry = ".Package(url: \"\(url)\", majorVersion: \(choice.major))"
        }
        
        console.print("Add the following entry to your Package.swift dependencies array:")
        console.print()
        console.print("    \(packageEntry)")
        console.print()
        
        if console.confirm("Would you like to add this automatically?") {
            let split = package.components(separatedBy: "dependencies: [\n")
            guard split.count == 2 else {
                throw CommandError.general("Incompatible Package.swift format, please add manually.")
            }
            
            var new = String(split[0]) ?? ""
            new += "dependencies: [\n"
            new += "        " + packageEntry + ",\n"
            new += String(split[1]) ?? ""
            
            try DataFile.save(bytes: new.makeBytes(), to: "Package.swift")
            
            console.success("Added \(repo) version \(choice.special) to Package.swift.")
            
            console.print("Project update required after changing dependencies.")
            if console.confirm("Update project now?") {
                let update = Update(console: console)
                try update.run(arguments: arguments)
            }
        } else {
            console.warning("Remember to run `vapor update` after you modify your Package.swift.")
        }
    }
}


struct Tag: JSONInitializable, CustomStringConvertible {
    var name: String
    var sha: String
    
    var major: Int
    var minor: Int
    var patch: Int
    
    init(json: JSON) throws {
        name = try json.get("name")
        sha = try json.get("commit.sha")
        let parts = name.components(separatedBy: ".")
        
        guard parts.count >= 3 else {
            major = 0
            minor = 0
            patch = 0
            return
        }
        
        major = Int(parts[0]) ?? 0
        minor = Int(parts[1]) ?? 0
        patch = Int(parts[2]) ?? 0
    }
    
    var special: String {
        if let pre = self.prereleaseIdentifier {
            return major.description + "-" + pre
        } else {
            return major.description
        }
    }
    
    var prereleaseIdentifier: String? {
        let parts = name.components(separatedBy: "-")
        if parts.count == 2 {
            return parts.last?.components(separatedBy: ".").first
        }
        return nil
    }
    
    var description: String {
        if let pre = self.prereleaseIdentifier {
            return "\(major).x (\(pre))"
        } else {
            return "\(major).x"
        }
    }
}
