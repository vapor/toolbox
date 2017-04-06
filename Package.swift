import PackageDescription

let package = Package(
    name: "VaporToolbox",
    targets: [
        Target(name: "VaporToolbox", dependencies: ["Cloud", "Shared"]),
        Target(name: "Executable", dependencies: ["VaporToolbox"]),
        Target(name: "Cloud", dependencies: ["Shared"]),
        Target(name: "Shared"),
    ],
    dependencies: [
        // Console protocols, terminal, and commands
        .Package(url: "https://github.com/vapor/console.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/json.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/vapor.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/redbird.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
    ]
)
