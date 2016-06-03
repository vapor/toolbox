#!/usr/bin/env swift

#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

@noreturn func fail(_ message: String) {
    print()
    print("Error: \(message)")
    print("Note: Make sure you are using Swift 3.0 Preview 1")
    exit(1)
}

enum Error: ErrorProtocol { // Errors pertaining to running commands
    case system(Int32)
    case cancelled
    case terminalSize
}

func run(_ command: String) throws {
    print("### CMD: \(command)")
    let result = system(command)

    if result == 2 {
        throw Error.cancelled
    } else if result != 0 {
        throw Error.system(result)
    }
}

func run(_ parts: [String]) throws {
    let cmd = parts.joined(separator: " ")
    try run(cmd)
}

func exists(path: String) -> Bool {
    return system("ls \(path) > /dev/null 2>&1") == 0
}

func curl(url: String, output: String, verbose: Bool = false, followRedirect: Bool = true) throws {
    var cmd = ["curl"]
    if !verbose {
        cmd.append("-s")
    }
    if followRedirect {
        cmd.append("-L")
    }
    cmd.append(url)
    cmd.append(contentsOf: ["-o", output])
    try run(cmd)
}

func unpack(archive: String, verbose: Bool = false) throws {
    var cmd = ["tar", "-x", "-z"]
    if verbose {
        cmd.append("-v")
    }
    cmd.append(contentsOf: ["-f", archive])
    try run(cmd)
}

func rm(directory: String) throws {
    guard
        directory != "/" ||
        directory != "~"
    else {
        fail("Will not remove directory '\(directory)'")
    }
    try run("rm -rf \(directory)")
}

func rm(file: String) throws {
    try run("rm \(file)")
}

func build(directory: String) throws {
    let cwd = "cd \(directory) &&"
    let cmd = [cwd, "swift", "build", "-c", "release"]
    try run(cmd)
}

let url = "https://github.com/qutheory/vapor-cli/archive/spm.tar.gz"
let archive = "./tmp.tgz"
let unpackedDir = "./vapor-cli-spm"

do {
    if !exists(path: archive) {
        print("Downloading \(url) ...")
        try curl(url: url, output: archive, verbose: true)
    }
} catch {
    fail("Could not download SPM package")
}

do {
    print("Unpacking \(archive) ...")
    try unpack(archive: archive, verbose: false)
} catch {
    fail("Could not unpack archive")
}

do {
    print("Building package ...")
    try build(directory: unpackedDir)
} catch {
    fail("Could not build package")
}

print("Cleaning up ...")

do {
    if exists(path: unpackedDir) {
        try rm(directory: unpackedDir)
    }
} catch {
    fail("Could not remove directory '\(unpackedDir)'")
}

do {
    if exists(path: archive) {
        try rm(file: archive)
    }
} catch {
    fail("Could not remove archive '\(archive)'")
}

print("Done.")
