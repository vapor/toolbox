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
        var provider = arguments[1]
        
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
        
        let drop = try Droplet()
        
        let isVerbose = arguments.isVerbose
        let cloneBar = console.loadingBar(title: "Loading \(repo) tags", animated: !isVerbose)
        cloneBar.start()
    
        let res: Response
        do {
            res = try drop.client.get("https://api.github.com/repos/\(repo)/tags")
            cloneBar.finish()
        } catch {
            cloneBar.fail()
            throw CommandError.general("GitHub API request failed")
        }
        
        guard res.status == .ok else {
            throw CommandError.general("Could not find \(repo)")
        }
        
        guard let tagsArray = res.json?.array else {
            throw CommandError.general("Invalid tags response from GitHub")
        }
        
        let tags = try tagsArray.map { tagJSON in
            return try Tag(json: tagJSON)
        }
        
        var majorVersions: [Int: Tag] = [:]
        for tag in tags.reversed() {
            majorVersions[tag.major] = tag
        }
        
        let choices: [Tag] = majorVersions
            .values
            .array
            .sorted(by: { $0.major > $1.major })
        
        let choice = try console.giveChoice(title: "Which version?", in: choices)
        
        let url = "https://github.com/\(repo).git"
        let packageEntry = ".Package(url: \"\(url)\", majorVersion: \(choice.major))"
        
        let package = try console.backgroundExecute(program: "cat", arguments: ["Package.swift"])
        
        guard !package.contains(repo) else {
            throw CommandError.general("Package.swift already contains \(provider)")
        }
        
        let split = package.components(separatedBy: "dependencies: [\n")
        guard split.count == 2 else {
            throw CommandError.general("Invalid Package.swift format.")
        }
        
        var new = String(split[0]) ?? ""
        new += "dependencies: [\n"
        new += "        " + packageEntry + ",\n"
        new += String(split[1]) ?? ""
        new = new.components(separatedBy: "\"").joined(separator: "\\\"")
        
        _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "echo \"\(new)\" > Package.swift"])
        
        console.success("Added \(repo) version \(choice.name)")
    
        console.print("Project update required after changing dependencies.")
        if console.confirm("Update project now?") {
            let update = Update(console: console)
            try update.run(arguments: arguments)
        }
    }
}


struct Tag: JSONInitializable, CustomStringConvertible {
    var name: String
    var sha: String
    var major: Int
    
    init(json: JSON) throws {
        name = try json.get("name")
        sha = try json.get("commit.sha")
        major = Int(String(name.characters.first!)) ?? 0
    }
    
    var description: String {
        return name
    }
}
