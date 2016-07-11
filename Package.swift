import PackageDescription

let package = Package(
    name: "VaporToolbox",
    exclude: ["bootstrap.swift"],
	dependencies: [
        // libc
        .Package(url: "https://github.com/qutheory/libc.git", majorVersion: 0, minor: 1),
        
        // Console protocols, terminal, and commands
        .Package(url: "https://github.com/qutheory/console.git", majorVersion: 0, minor: 1),
	],
    targets: [
		Target(name: "VaporToolbox"),
		Target(name: "Executable", dependencies: ["VaporToolbox"])
    ]
)
