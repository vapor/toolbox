import PackageDescription

let package = Package(
    name: "VaporToolbox",
    targets: [
        Target(name: "VaporToolbox"),
        Target(name: "Executable", dependencies: ["VaporToolbox"])
    ],
    dependencies: [
        // Console protocols, terminal, and commands
        .Package(url: "https://github.com/vapor/console.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/json.git", Version(2,0,0, prereleaseIdentifiers: ["beta"]))
    ]
)
