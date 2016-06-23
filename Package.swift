import PackageDescription

let package = Package(
    name: "Vapor-cli",
    exclude: ["bootstrap.swift"],
    targets: [
        Target(name: "vapor"),
        Target(name: "vapor-main", dependencies: [ .Target(name: "vapor") ])
    ]
)
