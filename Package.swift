import PackageDescription

let package = Package(
    name: "VaporToolbox",
    targets: [
        Target(name: "VaporToolbox"),
        Target(name: "Executable", dependencies: ["VaporToolbox"])
    ],
    dependencies: [
        // Console protocols, terminal, and commands
        .Package(url: "https://github.com/vapor/console.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/json.git", majorVersion: 2)
    ]
)
