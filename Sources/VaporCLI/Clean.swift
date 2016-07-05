
struct Clean: Command {
    static let id = "clean"
    static func execute(with args: [String], in shell: PosixSubsystem) throws {
        guard args.isEmpty else {
            throw Error.failed("\(id) does not take any additional parameters")
        }

        do {
            try shell.run("rm -rf Packages .build")
            print("Cleaned.")
        } catch {
            // re-throw with new error message
            throw Error.failed("Could not clean.")
        }
    }
}

