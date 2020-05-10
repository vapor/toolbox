import Foundation

var execPid: pid_t?

func exec(_ program: String, _ arguments: String...) throws {
    try exec(program, arguments)
}

func exec(_ program: String, _ arguments: [String]) throws {
    var pid = pid_t()

    /*
     
     There is an error when running command 'vapor-beta run' on raspberry pi 4 Ubuntu 20.04 Swift 5.2.3
     
     Fatal error: Unexpectedly found nil while implicitly unwrapping an Optional value: file /home/ubuntu/toolbox-18.0.0-beta.28/Sources/VaporToolbox/exec.swift, line 13

    */
    
    // Usinng '#if os(Linux)' and 'posix_spawn_file_actions_t()' to fix issue described above
    // Need to check if this doesn't break things on other distributions and devices
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

    /*
    
     There is an error when building toolbox-18.0.0-beta.28 on raspberry pi 4 Ubuntu 20.04 Swift 5.2.3
     
     /home/ubuntu/toolbox-18.0.0-beta.28/Sources/VaporToolbox/exec.swift:36:42: error: value of optional type 'UnsafeMutablePointer<Int8>?' must be unwrapped to a value of type 'UnsafeMutablePointer<Int8>'
     let spawned = posix_spawnp(&pid, argv[0], &fileActions, nil, argv + [nil], envp + [nil])
     
    */

    // Using compactMap to fix issue described above
    // Need to check if this doesn't break things on other distributions and devices
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
