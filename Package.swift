import PackageDescription

let package = Package(
    name: "VaporCLI",
    exclude: ["bootstrap.swift"],
    targets: [
        Target(name: "VaporCLI"),
        Target(name: "vapor", dependencies: [ .Target(name: "VaporCLI") ])
    ]
)
