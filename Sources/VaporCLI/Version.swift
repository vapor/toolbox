public final class Version: Command {
    public override func run() throws {
        try super.run()
        
        print("Vapor CLI version: \(VaporConsole.version)")
    }

    public override func help() {
        print("Displays Vapor CLI version")
    }
}
