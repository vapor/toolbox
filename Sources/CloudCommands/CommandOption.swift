import Vapor
import Globals

extension CommandOption {
    static let email: CommandOption = .value(
        name: "email",
        short: "e",
        default: nil,
        help: ["the email to use."]
    )

    static let password: CommandOption = .value(
        name: "password",
        short: "p",
        default: nil,
        help: ["the password to use."]
    )

    static let firstName: CommandOption = .value(
        name: "first-name",
        short: "f",
        default: nil,
        help: ["your first name."]
    )

    static let lastName: CommandOption = .value(
        name: "last-name",
        short: "l",
        default: nil,
        help: ["your last name."]
    )

    static let org: CommandOption = .value(
        name: "org",
        short: "o",
        default: nil,
        help: ["organization name to use."]
    )

    static let all: CommandOption = .flag(
        name: "all",
        short: "a",
        help: ["include more complete data."]
    )
}

extension CommandOption {
    static let app: CommandOption = .value(
        name: "app",
        short: "a",
        default: nil,
        help: [
            "the slug associated with your app."
        ]
    )

    static let lines: CommandOption = .value(
        name: "lines",
        short: "l",
        default: "200",
        help: ["if passed, should show timestamps"]
    )

    static let showTimestamps: CommandOption = .flag(
        name: "show-timestamps",
        short: "t",
        help: ["if passed, should show timestamps"]
    )

    static let env: CommandOption = .value(
        name: "env",
        short: "e",
        default: nil,
        help: [
            "the environment to use."
        ]
    )
    static let branch: CommandOption = .value(
        name: "branch",
        short: "b",
        default: nil,
        help: [
            "the branch to use. If different than default."
        ]
    )

    static let force: CommandOption = .flag(
        name: "force",
        short: "f",
        help: [
            "force the operation.",
            "you WILL lose data.",
            "this action is irreversible.",
        ]
    )

    static let push: CommandOption = .flag(
        name: "push",
        short: "p",
        help: [
            "push to cloud as well."
        ]
    )
}
extension CommandOption {
    static let readableName: CommandOption = .value(
        name: "readable-name",
        short: "n",
        default: nil,
        help: ["the readable name to give your key."]
    )
    static let path: CommandOption = .value(
        name: "path",
        short: "p",
        default: nil,
        help: ["a custom path to the public key that should be pushed."]
    )
    static let key: CommandOption = .value(
        name: "key",
        short: "k",
        default: nil,
        help: ["use this to pass the contents of your public key directly."]
    )
}

extension CommandContext {
    func load(_ option: CommandOption, _ message: String? = nil, secure: Bool = false) -> String {
        if let value = options[option.name] { return value }
        console.pushEphemeral()
        let message = message ?? option.name
        let answer = console.ask(message.consoleText(), isSecure: secure)
        console.popEphemeral()
        return answer
    }

    func flag(_ option: CommandOption) -> Bool {
        todo()
//        return options[option.name]?.bool == true
    }
}

extension Dictionary where Key == String, Value == String {
    public func value(_ option: CommandOption) -> String? {
        return self[option.name]
    }
}
