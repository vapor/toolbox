#!/usr/bin/env swift

#if os(OSX)
    import Darwin
#else
    import Glibc
#endif
import Foundation

func printFailure(_ message: String) {
    print()
    print("Error: \(message)")
    print("Note: Make sure you are using Swift version DEVELOPMENT-SNAPSHOT-2016-06-20-a")
}

enum Error: ErrorProtocol { // Errors pertaining to running commands
    case system(Int32)
    case cancelled
    case commandNotFound
    case failed(String)
}

// FIXME: Sven: This code is duplicated almost 1:1 from PosixSubsystem.swift and
// does not have any tests against it at the moment. We can't break this script
// up, because it needs to be downloaded and executed to install the package.
// Is there a way to make this testable while still keeping it as a standalone
// script?
// At the very least we should make sure the essential parts of this script
// are idential to a tested version in PosixSubsystem.
// Could a workaround be to make bootstrap.swift a concatenation of a tested
// file in the package plus a very small `main` body, like the CLI? I.e.:
//   cat PosixSubsystem.swift bootstrap_main.swift > bootstrap.swift

// wrappers for a few low level C calls, based on
// https://github.com/apple/swift-package-manager/blob/master/Sources/POSIX/system.swift

private func _WSTATUS(_ status: CInt) -> CInt {
    return status & 0x7f
}

private func WIFEXITED(_ status: CInt) -> Bool {
    return _WSTATUS(status) == 0
}

private func WEXITSTATUS(_ status: CInt) -> CInt {
    return (status >> 8) & 0xff
}

func waitpid(_ pid: pid_t) throws -> Int32 {
    while true {
        var exitStatus: Int32 = 0
        let rv = waitpid(pid, &exitStatus, 0)

        if rv != -1 {
            if WIFEXITED(exitStatus) {
                return WEXITSTATUS(exitStatus)
            } else {
                throw Error.system(exitStatus)
            }
        } else if errno == EINTR {
            continue  // see: man waitpid
        } else {
            throw Error.system(errno)
        }
    }
}

func posix_spawnp(args: [String]) throws -> pid_t {
    var environment = [String: String]()
    for key in ["PATH", "HOME"] {
        if let e = getenv(key) {
            environment[key] = String(validatingUTF8: e)
        }
    }

    let env: [UnsafeMutablePointer<CChar>?] = environment.map{ "\($0.0)=\($0.1)".withCString(strdup) }
    defer { for case let arg? in env { free(arg) } }

    var pid: pid_t = 0
    let argv = args.map{ $0.withCString(strdup) } + [nil]
    defer { for case let arg? in argv { free(arg) } }

    let res = posix_spawnp(&pid, argv[0], nil, nil, argv, env + [nil])

    if res == 0 {
        return pid
    } else {
        throw Error.system(res)
    }
}

func system(_ command: String) throws -> Int32 {
    let command = ["/bin/sh", "-c", command]
    let pid = try posix_spawnp(args: command)
    return try waitpid(pid)
}

func run(_ arguments: [String], silent: Bool = false) throws {
    var command = arguments.joined(separator: " ")
    if silent {
        command.append("> /dev/null 2>&1")
    }

    let result = try system(command)

    if result == 2 {
        throw Error.cancelled
    } else if result != 0 {
        throw Error.system(result)
    }
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
    do {
        return try system("which \(name) > /dev/null 2>&1") == 0
    } catch {
        return false
    }
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
        throw Error.failed("Will not remove directory '\(directory)'")
    }
    try run(["rm", "-rf", directory])
}

func rm(file: String) throws {
    try run(["rm", file])
}

func build(directory: String) throws {
    print(directory)
    let cmd = ["swift", "build", "-C", directory, "-c", "release"]
    try run(cmd)
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

func bootstrap(repository: String, branch: String, path: String) throws {
    let url = downloadURL(repository: repository, branch: branch)
    let archive = "./tmp.tgz"
    // this directory name is dermined by how github creates the tar.gz
    let unpackedDir = "./\(repository)-\(branch)"

    // download package
    do {
        if !exists(path: archive) {
            print("Downloading \(url) ...")
            try download(url: url, output: archive, verbose: false)
        }
    } catch {
        throw Error.failed("Could not download SPM package")
    }
    defer {
        if exists(path: archive) {
            do {
                try rm(file: archive)
            } catch { /* ignored */ }
        }
    }

    // unpack archive
    do {
        try unpack(archive: archive, verbose: false)
    } catch {
        throw Error.failed("Could not unpack archive")
    }
    defer {
        if exists(path: unpackedDir) {
            do {
                try rm(directory: unpackedDir)
            } catch { /* ignored */ }
        }
    }

    // build package
    do {
        print("Building package ...")
        try build(directory: unpackedDir)
    } catch {
        throw Error.failed("Could not build package")
    }

    do {
        _ = try system("./\(unpackedDir)/.build/release/VaporToolbox self install --path=\(installPath)")
    } catch {
        throw Error.failed("Could not install toolbox.")
    }
}

// main

let installPath = Process.arguments.count > 1
    ? Process.arguments[1]
    : "/usr/local/bin/vapor"
let branch = Process.arguments.count > 2
    ? Process.arguments[2]
    : "master"

do {
    try bootstrap(repository: "vapor-toolbox", branch: branch, path: installPath)
} catch Error.failed(let msg) {
    printFailure(msg)
} catch {
    print("Unexpected Error")
}