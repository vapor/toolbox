import PackageDescription

let package = Package(
    name: "VaporToolbox",
    targets: [
        Target(name: "VaporToolbox"),
        Target(name: "Executable", dependencies: ["VaporToolbox"])
    ],
    dependencies: [
        // Console protocols, terminal, and commands
        .Package(url: "https://github.com/qutheory/console.git", majorVersion: 0, minor: 4),
    ]
)
