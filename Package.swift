// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "VaporToolbox",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", .branch("master")),
        .package(url: "https://github.com/tanner0101/swift-syntax", .branch("static")),
//        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/leaf-kit.git", from: "0.0.2"),
        // ::vapor
    ],
    targets: [
        // All of the commands and logic that powers the Vapor toolbox
        .target(name: "VaporToolbox", dependencies: [
            "LinuxTestsGeneration",
           "Vapor",
           "CloudCommands",
           "Globals",
//           "Leaf",
           "LeafKit",
        ]),
        .target(name: "LinuxTestsGeneration", dependencies: [
            "SwiftSyntax",
            "Globals",
        ]),
        .target(name: "CloudCommands", dependencies: [
            "Vapor",
            "CloudAPI",
            "Globals",
        ]),
        .target(name: "CloudAPI", dependencies: [
            "Vapor",
            "Globals",
        ]),
        .target(name: "Globals", dependencies: [
            "Vapor",
        ]),
        .testTarget(name: "LinuxTestsGenerationTests", dependencies: [
            "LinuxTestsGeneration",
        ]),
        // Runnable module, executes the main command group.
        .target(name: "Executable", dependencies: ["VaporToolbox"]),
    ]
)
