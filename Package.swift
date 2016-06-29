import PackageDescription

let package = Package(
    name: "VaporCLI",
    exclude: ["bootstrap.swift"],
    targets: [
        Target(name: "libc"),
        Target(name: "VaporCLI", dependencies: [ .Target(name: "libc")]),
        Target(name: "vapor", dependencies: [ .Target(name: "VaporCLI") ])
    ]
)
