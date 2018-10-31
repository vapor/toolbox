import Vapor

extension CommandOption {
    static let email: CommandOption = .value(
        name: "email",
        short: "e",
        default: nil,
        help: ["The email to use."]
    )

    static let password: CommandOption = .value(
        name: "password",
        short: "p",
        default: nil,
        help: ["The password to use."]
    )

    static let firstName: CommandOption = .value(
        name: "first-name",
        short: "f",
        default: nil,
        help: ["Your first name."]
    )

    static let lastName: CommandOption = .value(
        name: "last-name",
        short: "l",
        default: nil,
        help: ["Your last name."]
    )

    static let org: CommandOption = .value(
        name: "org",
        short: "o",
        default: nil,
        help: ["Organization name to use."]
    )

    static let all: CommandOption = .flag(
        name: "all",
        short: "a",
        help: ["Include more complete data."]
    )
}

extension CommandContext {
    func load(_ option: CommandOption, _ message: String? = nil) -> String {
        if let value = options[option.name] { return value }
        console.pushEphemeral()
        let message = message ?? option.name
        let answer = console.ask(message.consoleText())
        console.popEphemeral()
        return answer
    }

    func flag(_ option: CommandOption) -> Bool {
        return options[option.name]?.bool == true
    }
}

extension Dictionary where Key == String, Value == String {
    func value(_ option: CommandOption) -> String? {
        return self[option.name]
    }
}
