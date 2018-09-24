// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "VaporToolbox",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
         .package(url: "https://github.com/apple/swift-syntax", from: "0.40200.0"), // .branch("swift-4.2-branch")),
    ],
    targets: [
        // All of the commands and logic that powers the Vapor toolbox
        .target(name: "VaporToolbox", dependencies: [
            "SwiftSyntax",
            "Vapor",
        ]),

        // Runnable module, executes the main command group.
        .target(name: "Executable", dependencies: ["VaporToolbox"]),
    ]
)
