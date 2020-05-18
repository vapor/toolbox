import Foundation

var execPid: pid_t?

func exec(_ program: String, _ arguments: String...) throws {
    try exec(program, arguments)
}

func exec(_ program: String, _ arguments: [String]) throws {
    var pid = pid_t()

    #if os(Linux)
    var fileActions = posix_spawn_file_actions_t()
    #else
    var fileActions: posix_spawn_file_actions_t!
    #endif

    posix_spawn_file_actions_init(&fileActions)
    defer {
        posix_spawn_file_actions_destroy(&fileActions)
    }

    posix_spawn_file_actions_adddup2(&fileActions, FileHandle.standardInput.fileDescriptor, 0)
    posix_spawn_file_actions_adddup2(&fileActions, FileHandle.standardOutput.fileDescriptor, 1)
    posix_spawn_file_actions_adddup2(&fileActions, FileHandle.standardError.fileDescriptor, 2)

    let argv = ([program] + arguments).compactMap {
        $0.withCString(strdup)
    }
    defer {
        argv.forEach { free($0) }
    }

    let envp: [UnsafeMutablePointer<CChar>?] = ProcessInfo.processInfo.environment
        .map{ "\($0.0)=\($0.1)" }
        .map { $0.withCString(strdup) }
    defer {
        envp.forEach { free($0) }
    }

    let spawned = posix_spawnp(&pid, argv[0], &fileActions, nil, argv + [nil], envp + [nil])
    if spawned != 0 {
        fatalError("spawned")
    }

    var result: Int32 = 0
    execPid = pid
    pid = waitpid(pid, &result, 0)
    execPid = nil
    result = result / 256

    if result == ENOENT {
        fatalError("enoent")
    } else if result != 0 {
        fatalError("result \(result)")
    }
}
