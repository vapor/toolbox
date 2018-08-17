// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "VaporToolbox",
    dependencies: [
        // The Package Manager for the Swift Programming Language
        .package(url: "https://github.com/apple/swift-package-manager", from: "0.1.0"),

        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
    targets: [
        // All of the commands and logic that powers the Vapor toolbox
        .target(name: "VaporToolbox", dependencies: ["SwiftPM", "Vapor"]),

        // Runnable module, executes the main command group.
        .target(name: "Executable", dependencies: ["VaporToolbox"]),
    ]
)
