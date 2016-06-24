import PackageDescription

let package = Package(
    name: "VaporCLI",
    exclude: ["bootstrap.swift"],
    targets: [
        Target(name: "Libc"),
        Target(name: "VaporCLI", dependencies: [ .Target(name: "Libc")]),
        Target(name: "vapor", dependencies: [ .Target(name: "VaporCLI") ])
    ]
)
