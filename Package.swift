// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "toolbox",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "vapor", targets: ["VaporToolbox"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.2"),
        .package(url: "https://github.com/vapor/console-kit.git", exact: "5.0.0-beta.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "1.0.0"),
        .package(url: "https://github.com/hummingbird-project/swift-mustache.git", from: "2.1.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.2"),
    ],
    targets: [
        .executableTarget(
            name: "VaporToolbox",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ConsoleKit", package: "console-kit"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "Mustache", package: "swift-mustache"),
                .product(name: "Yams", package: "yams"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaporToolboxTests",
            dependencies: [
                .target(name: "VaporToolbox"),
                .target(name: "BuildToolbox"),
            ],
            resources: [
                .copy("Manifests")
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "BuildToolbox",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess")
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .treatAllWarnings(as: .error),
        .strictMemorySafety(),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("LifetimeDependence"),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("ImmutableWeakCaptures"),
    ]
}
