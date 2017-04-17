import Console
import libc

public final class Update: Command {
    public let id = "update"

    public let signature: [Argument] = [
        Option(name: "xcode", help: ["Removes any Xcode projects while cleaning."])
    ]

    public let help: [String] = [
        "Updates your dependencies."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        try checkGitUpstream()

        let isVerbose = arguments.isVerbose
        let bar = console.loadingBar(title: "Updating", animated: !isVerbose)
        bar.start()
        try console.execute(verbose: isVerbose, program: "swift", arguments: ["package", "update"])
        bar.finish()

        #if !os(Linux)
            console.info("Changes to dependencies usually require Xcode to be regenerated.")
            let shouldGenerateXcode = console.confirm("Would you like to regenerate your xcode project now?")
            guard shouldGenerateXcode else { return }
            let xcode = Xcode(console: console)
            try xcode.run(arguments: arguments)
        #endif
    }

    func checkGitUpstream() throws {
        guard gitInfo.isGitProject() else { return }
        let currentBranch = try gitInfo.currentBranch()
        
        if let upstream = try? gitInfo.upstreamBranch() {
            try gitInfo.verify(
                local: currentBranch,
                remote: upstream.remote,
                upstream: upstream.branch
            )
        } else {
            let remotes = try gitInfo.remoteNames()
            let remote: String
            if remotes.isEmpty {
                return
            } else if remotes.count == 1 {
                remote = remotes[0]
            } else if remotes.contains("origin") {
                remote = "origin"
            } else {
                remote = try console.giveChoice(
                    title: "Which remote are you tracking for '\(currentBranch)'?",
                    in: remotes
                )
            }
            try gitInfo.verify(
                local: currentBranch,
                remote: remote
            )
        }
    }
}
