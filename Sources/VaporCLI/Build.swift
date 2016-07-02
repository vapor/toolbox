public final class Build: Command {
    public static let id = "build"

    public override func run() throws {

        let loadingBar = self.loadingBar(title: "Build")
        loadingBar.start()

        let tmpFile = "/var/tmp/vaporBuildOutput.log"

        do {
            try shell.run("swift package fetch > \(tmpFile) 2>&1")
        } catch Error.shell(_) {
            loadingBar.fail()
            try shell.run("tail \(tmpFile)")
            throw Error.general("Could not fetch dependencies.")
        }

        var buildFlags: [String] = [
            "-Xswiftc",
            "-I/usr/local/include/mysql",
            "-Xlinker",
            "-L/usr/local/lib"
        ]

        for (name, value) in options {
            if name == "release" && value.bool == true {
                buildFlags += "--configuration release"
            } else {
                buildFlags += "--\(name)=\(value.string ?? "")"
            }
        }

        let command = "swift build " + buildFlags.joined(separator: " ")
        do {
            try shell.run("\(command) > \(tmpFile) 2>&1")
            loadingBar.finish()
        } catch Error.shell(_) {
            loadingBar.fail()
            print()
            info("Command:")
            print(command)
            print()
            info("Output:")
            try shell.run("tail \(tmpFile)")
            print()
            info("Toolchain:")
            try shell.run("which swift")
            print()
            info("Need help getting your project to build?")
            print("Join our Slack where hundreds of contributors")
            print("are waiting to help: http://slack.qutheory.io")

            throw Error.general("There may be something wrong in the source code or structure of your project.")
        }
    }

    public override func help() {
        print("build <module-name>")
        print("Builds source files and links Vapor libs.")
        print("Defaults to App/ folder structure.")
    }
}
