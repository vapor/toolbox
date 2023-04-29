import ConsoleKit
import Foundation

struct SupervisorInit: Command {
    struct Signature: CommandSignature {
        init() { }
    }

    var help: String {
        "Creates a Supervisor entry for the current project"
    }

    func run(using context: CommandContext, signature: Signature) throws {
        context.console.warning("This command is deprecated. Follow the docs for the latest instructions at https://docs.vapor.codes/deploy/supervisor/")

        let package = try Process.swift.package.dump()
        let cwd = FileManager.default.currentDirectoryPath
        let user = NSUserName()
        let config = SupervisorConfiguration(
            program: package.name,
            attributes: [
                "command": "\(cwd)/.build/release/App serve --env production",
                "directory": cwd,
                "user": user,
                "stdout_logfile": "/var/log/supervisor/\(package.name)-stdout.log",
                "stderr_logfile": "/var/log/supervisor/\(package.name)-stdout.log",
            ]
        )
        #if os(macOS)
        let prefix = "/usr/local/share/supervisor"
        #else
        let prefix = "/etc/supervisor"
        #endif
        let directory = "\(prefix)/conf.d"
        try FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true
        )
        let path = "\(directory)/\(package.name).conf"
        FileManager.default.createFile(atPath: path, contents: .init(config.serialize().utf8))
        context.console.print("Supervisor configuration created: \(path).")
        try SupervisorUpdate().run(using: context, signature: .init())
    }
}
