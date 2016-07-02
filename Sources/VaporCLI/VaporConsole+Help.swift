extension VaporConsole {
    func help(_ executable: String) {
        print("Usage: \(executable) [", newLine: false)
        print(commands.map { (id, commandType) in
            return id
            }.joined(separator: "|"), newLine: false)
        print("]")

        print()

        for (id, commandType) in commands {
            info(id)
            let command = commandType.init(
                console: self,
                shell: shell,
                arguments: [],
                options: [:]
            )
            command.help()
            print()
        }

        print("Join our Slack if you have questions,")
        print("need help, or want to contribute.")
        print("http://slack.qutheory.io")

        print()
    }
}