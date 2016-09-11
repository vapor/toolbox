import PackageDescription

let package = Package(
    name: "VaporToolbox",
    targets: [
        Target(name: "VaporToolbox"),
        Target(name: "Executable", dependencies: ["VaporToolbox"])
    ],
    dependencies: [
        // Console protocols, terminal, and commands
        .Package(url: "https://github.com/vapor/console.git", majorVersion: 0, minor: 7),
        .Package(url: "https://github.com/vapor/json.git", majorVersion: 0)
    ]
)
