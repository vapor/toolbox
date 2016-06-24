
struct Clean: Command {
    static let id = "clean"
    static func execute(with args: [String], in directory: String, shell: PosixSubsystem) {
        guard args.isEmpty else {
            fail("\(id) doesn't take any additional parameters")
        }

        do {
            try run("rm -rf Packages .build")
            print("Cleaned.")
        } catch {
            fail("Could not clean.")
        }
    }
}

