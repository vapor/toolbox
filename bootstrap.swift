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
    case commandNotFound
}

func run(_ command: String) throws {
    let result = system(command)

    if result == 2 {
        throw Error.cancelled
    } else if result != 0 {
        throw Error.system(result)
    }
}

func run(_ parts: [String], silent: Bool = false) throws {
    var cmd = parts.joined(separator: " ")
    if silent {
        cmd.append("> /dev/null 2>&1")
    }
    try run(cmd)
}

func exists(path: String) -> Bool {
    var s = stat()
    return stat(path, &s) == 0
}

func isDir(path: String) -> Bool {
    var s = stat()
    let res = stat(path, &s)
    if res != 0 {
        return false
    } else {
        return (s.st_mode & S_IFDIR) != 0
    }
}

func hasCommand(_ name: String) -> Bool {
    return system("which \(name) > /dev/null 2>&1") == 0
}

func curl(url: String, output: String, verbose: Bool = false, followRedirect: Bool = true) throws {
    guard hasCommand("curl") else {
        throw Error.commandNotFound
    }

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

func wget(url: String, output: String, verbose: Bool = false) throws {
    guard hasCommand("wget") else {
        throw Error.commandNotFound
    }

    var cmd = ["wget"]
    if !verbose {
        cmd.append("-q")
    }
    cmd.append(url)
    cmd.append(contentsOf: ["-O", output])
    try run(cmd)
}

func download(url: String, output: String, verbose: Bool = false, followRedirect: Bool = true) throws {
    do {
        try curl(url: url, output: output, verbose: verbose, followRedirect: followRedirect)
    } catch Error.commandNotFound {
        // curl may not be available
        try wget(url: url, output: output, verbose: verbose)
    }
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
    try run(cmd, silent: true)
}

func downloadURL(repository: String, branch: String = "master") -> String {
    return "https://github.com/qutheory/\(repository)/archive/\(branch).tar.gz"
}

func install(from: String, to: String) throws {
    let cmd = ["mv", from, to]
    do {
        try run(cmd)
    } catch {
        try run(["sudo"] + cmd)
    }
}

func trimTrailingSlash(path: String) -> String {
    var p = path
    if p.characters.last == "/" {
        p.remove(at: p.index(before: p.endIndex))
    }
    return p
}

func bootstrap(repository: String, branch: String, targetDir: String) {
    guard isDir(path: targetDir) else {
        fail("Install location '\(targetDir)' is not a directory")
    }
    let targetDir = trimTrailingSlash(path: targetDir)

    let url = downloadURL(repository: repository, branch: branch)
    let archive = "./tmp.tgz"
    // this directory name is dermined by how github creates the tar.gz
    let unpackedDir = "./\(repository)-\(branch)"

    do {
        if !exists(path: archive) {
            print("Downloading \(url) ...")
            try download(url: url, output: archive, verbose: false)
        }
    } catch {
        fail("Could not download SPM package")
    }

    do {
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

    let target = "\(targetDir)/vapor"
    do {
        let binary = "\(unpackedDir)/.build/release/vapor"
        try install(from: binary, to: target)
    } catch {
        fail("Could not install binary in \(targetDir)")
    }

    do { // remove build directory
        if exists(path: unpackedDir) {
            try rm(directory: unpackedDir)
        }
    } catch {
        fail("Could not remove directory '\(unpackedDir)'")
    }
    
    do { // remove tar.gz archive
        if exists(path: archive) {
            try rm(file: archive)
        }
    } catch {
        fail("Could not remove archive '\(archive)'")
    }

    print("Vapor CLI successfully installed in \(target)")
}

// main

let targetDir: String = {
    if Process.arguments.count > 1 {
        return Process.arguments[1]
    } else {
        return "/usr/local/bin"
    }
}()

bootstrap(repository: "vapor-cli", branch: "spm", targetDir: targetDir)
