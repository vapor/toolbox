import Vapor
import Globals

extension Option where Value == Int {
    static var lines: Option {
        let def = "200"
        return .init(name: "lines", short: "l", type: .value(default: def), help: "the number of lines to show, default '\(def)'.")
    }
}

extension Option where Value == String {
    static var email: Option {
        return .init(name: "email", short: "e", type: .value, help: "the email to use.")
    }
    static var password: Option {
        return .init(name: "password", short: "p", type: .value, help: "the password to use.")
    }
    static var firstName: Option {
        return .init(name: "first-name", short: "f", type: .value, help: "your first name.")
    }
    static var lastName: Option {
        return .init(name: "last-name", short: "l", type: .value, help: "your last name.")
    }
    static var org: Option {
        return .init(name: "org", short: "o", type: .value, help: "which organization to use.")
    }
    
    static var app: Option {
        return .init(name: "app", short: "a", type: .value, help: "the slug associated with your app.")
    }
    
    static var env: Option {
        return .init(name: "env", short: "e", type: .value, help: "the environment to use.")
    }
    static var branch: Option {
        return .init(name: "branch", short: "b", type: .value, help: "the branch to use, if other than app's default.")
    }
    
    static var readableName: Option {
        return .init(name: "readable-name", short: "n", type: .value, help: "a human readable name to use.")
    }
    
    static var path: Option {
        return .init(name: "path", short: "p", type: .value, help: "a custom path to use if desired.")
    }
    
    static var key: Option {
        return .init(name: "key", short: "k", type: .value, help: "use this to pass the contents of your public key directly.")
    }
}

extension Option where Value == Bool {
    static var all: Option {
        return .init(name: "all", short: "a", type: .flag, help: "include more data.")
    }
    static var showTimestamps: Option {
        return .init(name: "show-timestamps", short: "t", type: .flag, help: "if passed, should show timestamps.")
    }
    static var force: Option {
        return .init(name: "force", short: "f", type: .flag, help: "forces the operation. overwrites if necessary. you WILL lose overwritten data, this action is irreversible.")
    }
    static var push: Option {
        return .init(name: "push", short: "p", type: .flag, help: "push to cloud as well.")
    }
}

//    static let showTimestamps: CommandOption = .flag(
//        name: "show-timestamps",
//        short: "t",
//        help: ["if passed, should show timestamps"]
//    )
//
//
//    static let force: CommandOption = .flag(
//        name: "force",
//        short: "f",
//        help: [
//            "force the operation.",
//            "you WILL lose data.",
//            "this action is irreversible.",
//        ]
//    )
//
//    static let push: CommandOption = .flag(
//        name: "push",
//        short: "p",
//        help: [
//            "push to cloud as well."
//        ]
//    )
//}

//extension CommandOption {
//    static let email: CommandOption = .value(
//        name: "email",
//        short: "e",
//        default: nil,
//        help: ["the email to use."]
//    )
//
//    static let password: CommandOption = .value(
//        name: "password",
//        short: "p",
//        default: nil,
//        help: ["the password to use."]
//    )
//
//    static let firstName: CommandOption = .value(
//        name: "first-name",
//        short: "f",
//        default: nil,
//        help: ["your first name."]
//    )
//
//    static let lastName: CommandOption = .value(
//        name: "last-name",
//        short: "l",
//        default: nil,
//        help: ["your last name."]
//    )
//
//    static let org: CommandOption = .value(
//        name: "org",
//        short: "o",
//        default: nil,
//        help: ["organization name to use."]
//    )
//
//    static let all: CommandOption = .flag(
//        name: "all",
//        short: "a",
//        help: ["include more complete data."]
//    )
//}

//extension CommandOption {
//    static let app: CommandOption = .value(
//        name: "app",
//        short: "a",
//        default: nil,
//        help: [
//            "the slug associated with your app."
//        ]
//    )
//
//    static let lines: CommandOption = .value(
//        name: "lines",
//        short: "l",
//        default: "200",
//        help: ["if passed, should show timestamps"]
//    )
//
//    static let env: CommandOption = .value(
//        name: "env",
//        short: "e",
//        default: nil,
//        help: [
//            "the environment to use."
//        ]
//    )
//    static let branch: CommandOption = .value(
//        name: "branch",
//        short: "b",
//        default: nil,
//        help: [
//            "the branch to use. If different than default."
//        ]
//    )
//}

//extension CommandOption {
//    static let readableName: CommandOption = .value(
//        name: "readable-name",
//        short: "n",
//        default: nil,
//        help: ["the readable name to give your key."]
//    )
//    static let path: CommandOption = .value(
//        name: "path",
//        short: "p",
//        default: nil,
//        help: ["a custom path to the public key that should be pushed."]
//    )
//    static let key: CommandOption = .value(
//        name: "key",
//        short: "k",
//        default: nil,
//        help: ["use this to pass the contents of your public key directly."]
//    )
//}

extension LosslessStringConvertible {
    static func convertOrFail(_ raw: String) -> Self {
        if let val = self.init(raw) { return val }
        else { fatalError("unable to convert \(raw) to '\(type(of: Self.self))'") }
    }
}

extension CommandContext {
//    public func option<T>(_ path: KeyPath<Command.Signature, Option<T>>)throws -> T?
//        where T: LosslessStringConvertible
//    {
//        guard let raw = self.options[self.command.signature[keyPath: path].name] else {
//            return nil
//        }
//        guard let value = T.init(raw) else {
//            throw CommandError(identifier: "typeMismatch", reason: "Unable to convert `\(raw)` to type `\(T.self)`")
//        }
//        return value
//    }
    
    func load<V: LosslessStringConvertible>(_ opt: Option<V>, _ message: String? = nil, secure: Bool = false) -> V {
        if let raw = self.options[opt.name] {
            return V.convertOrFail(raw)
        }
        let msg = message ?? opt.name
        console.pushEphemeral()
        let answer = console.ask(msg.consoleText(), isSecure: secure)
        console.popEphemeral()
        return V.convertOrFail(answer)
    }
    
    func flag(_ opt: Option<Bool>) -> Bool {
        return self.options[opt.name].flatMap(Bool.init) ?? false
    }
    
//    func load(_ option: CommandOption, _ message: String? = nil, secure: Bool = false) -> String {
//        if let value = options[option.name] { return value }
//        console.pushEphemeral()
//        let message = message ?? option.name
//        let answer = console.ask(message.consoleText(), isSecure: secure)
//        console.popEphemeral()
//        return answer
//    }

//    func flag(_ option: CommandOption) -> Bool {
//        todo()
////        return options[option.name]?.bool == true
//    }
}

extension Dictionary where Key == String, Value == String {
    public func value<V: LosslessStringConvertible>(_ option: Option<V>) -> String? {
        return self[option.name]
    }
}
