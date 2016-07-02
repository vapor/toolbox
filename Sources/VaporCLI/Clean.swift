public final class Clean: Command {
    public static let id = "build"

    public override func run() throws {

        try shell.run("rm -rf Packages .build")

        if flag("xcode") {
            try shell.run("rm -rf *.xcodeproj")
        }

        success("Cleaned.")
    }

    public override func help() {
        print("cleans temporary build files")
        print("optionally removes generated Xcode Project")
    }
}
