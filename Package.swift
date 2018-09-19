// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "VaporToolbox",
    dependencies: [
//        // The Package Manager for the Swift Programming Language
//        .package(url: "https://github.com/apple/swift-package-manager.git", .revision("swift-DEVELOPMENT-SNAPSHOT-2018-09-18-a")),

        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "clibc"),
        
        // All of the commands and logic that powers the Vapor toolbox
        .target(name: "VaporToolbox", dependencies: [
//            "SwiftPM",
            "clibc",
            "Vapor"
        ]),

        // Runnable module, executes the main command group.
        .target(name: "Executable", dependencies: ["VaporToolbox"]),
    ]
)
